//
//  LyricManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

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
    
    func fetchData(songAndArtist: String, songName: String, songArtist: String) {
        self.songName = songName
        self.songArtist = songArtist
        var songURL = songAndArtist.replacingOccurrences(of: " ", with: "%2520")
        songURL = songURL.folding(options: .diacriticInsensitive, locale: .current)
        let request = NSMutableURLRequest(url: NSURL(string: "https://canarado-lyrics.p.rapidapi.com/lyrics/\(songURL)")! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: handle(data:response:error:))

        dataTask.resume()
    }
    
    func handle(data: Data?, response: URLResponse?, error: Error?) {
        if (error != nil) {
            print(error!)
            return
        }
        if let safeData = data {
            if let lyrics = self.parseJson(safeData) {
                // the triedOnce variable ensures that "no lyrics found" is showed after trying an alternate method of looking for lyrics from lyric API
                if lyrics == Constants.noLyrics && LyricManager.triedOnce == false {
                    LyricManager.triedOnce = true
                    // another way of getting lyrics if not found is trying just one artist instead of all
                    let songAndArtist = "\(songName) \(songArtist)"
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
            let songInfo = try decoder.decode(SongInfo.self, from: safeData)
            // loop through the array contents and match if the songName and lyrics are contained in the titles of the content
            print(songName)
            for(index, value) in songInfo.content.enumerated() {
                let potentialSongName = value.title.lowercased()
                // hopefully also include an and statement that will include the artist name for extra security/accuracy to get lyrics from API like the statement above
                if potentialSongName.contains(songName.lowercased()) {
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
}


