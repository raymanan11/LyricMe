//
//  LyricManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import NaturalLanguage

protocol LyricManagerDelegate : class {
    func updateLyrics(_ fullLyrics: String)
}

class LyricManager {
    var songName = ""
    var songArtist = ""
    
    var delegate: LyricManagerDelegate?
    
    static var triedOnce: Bool = false
    
    let headers = [
        "x-rapidapi-host": "canarado-lyrics.p.rapidapi.com",
        "x-rapidapi-key": Constants.rapidAPIKey
    ]
    
    func getLyrics(_ URL: NSURL) {
        let request = NSMutableURLRequest(url: URL as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: handle(data:response:error:))

        dataTask.resume()
    }
    
    func fetchData(songAndArtist: String, songName: String, songArtist: String) {
        self.songName = songName
        self.songArtist = songArtist
        let songURL = songAndArtist.replacingOccurrences(of: " ", with: "%2520")
        let urlOptionOne = songURL.folding(options: .diacriticInsensitive, locale: .current)
        let urlOptionTwo = songURL.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
        if let urlOne = NSURL(string: "https://canarado-lyrics.p.rapidapi.com/lyrics/\(urlOptionOne)") {
            getLyrics(urlOne)
        }
        else if let safeStringURL = urlOptionTwo, let urlTwo = NSURL(string: "https://canarado-lyrics.p.rapidapi.com/lyrics/\(safeStringURL)") {
            getLyrics(urlTwo)
        }
        else {
            print("unable to get")
        }
//        self.songName = songName
//        self.songArtist = songArtist
//        var songURL = songAndArtist.replacingOccurrences(of: " ", with: "%2520")
//
//        songURL = songURL.folding(options: .diacriticInsensitive, locale: .current)
//        let request = NSMutableURLRequest(url: NSURL(string: "https://canarado-lyrics.p.rapidapi.com/lyrics/\(songURL)")! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
//        request.httpMethod = "GET"
//        request.allHTTPHeaderFields = headers
//
//
//        let session = URLSession.shared
//        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: handle(data:response:error:))
//
//        dataTask.resume()
    }
    
    func handle(data: Data?, response: URLResponse?, error: Error?) {
        let songAndArtist = "\(songName) \(songArtist)"
        if (error != nil) {
            print(error!)
            print("Problem with Lyric API, calling again")
            fetchData(songAndArtist: songAndArtist, songName: self.songName, songArtist: self.songArtist)
            return
        }
        if let safeData = data {
            if let lyrics = self.parseJson(safeData) {
                // the triedOnce variable ensures that "no lyrics found" is showed after trying an alternate method of looking for lyrics from lyric API
                if lyrics == Constants.noLyrics && LyricManager.triedOnce == false {
                    LyricManager.triedOnce = true
                    // another way of getting lyrics if not found is trying just one artist instead of all
                    print("No lyrics found for singleArtist, trying again")
                    fetchData(songAndArtist: songAndArtist, songName: self.songName, songArtist: self.songArtist)
                }
                else {
                    delegate?.updateLyrics(lyrics)
                }
            }
        }
    }
    
    func parseJson(_ safeData: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let songInfo = try decoder.decode(CanaradoSongInfo.self, from: safeData)
            let spotifySongName = songName.lowercased().replacingOccurrences(of: " ", with: "")
            let spotifySongArtist = songArtist.lowercased().replacingOccurrences(of: " ", with: "")
            for(index, value) in songInfo.content.enumerated() {
                let potentialSongName = value.title.lowercased()
                let canaradoSongName = potentialSongName.filter { !$0.isWhitespace }
                if canaradoSongName.contains(spotifySongName) && canaradoSongName.contains(spotifySongArtist) {
                    print(potentialSongName)
                    return value.lyrics
                }
            }
            // if it reaches this point then that means it is not able to find lyrics
            return Constants.noLyrics
        }
        catch {
            print(error)
            return Constants.noLyrics
        }
    }
    
    func detectedLanguage(for string: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        guard let languageCode = recognizer.dominantLanguage?.rawValue else { return nil }
        let detectedLanguage = Locale.current.localizedString(forIdentifier: languageCode)
        return detectedLanguage
    }
    
}


