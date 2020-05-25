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

struct LyricManager {
    var songName = ""
    var songArtist = ""
    
    weak var delegate: LyricManagerDelegate?
    
    let headers = [
        "x-rapidapi-host": "canarado-lyrics.p.rapidapi.com",
        "x-rapidapi-key": Constants.rapidAPIKey
    ]
    
    mutating func fetchData(songAndArtist: String, songName: String, songArtist: String) {
        self.songName = songName
        self.songArtist = songArtist
        // PROBLEM: Some artists names cannot be recognized (i.e. Michael Bublé - can't recognize the é)
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
            print(error)
            return
        }
        if let safeData = data {
            if let lyrics = self.parseJson(safeData) {
                if(delegate != nil) {
                    delegate?.updateLyrics(lyrics)
                }
                else {
                    print("delegate is nil!")
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
            print(songArtist)
            for(index, value) in songInfo.content.enumerated() {
                print(value.title.lowercased())
//                print(songArtist.lowercased())
//                var songInfo = value.title.lowercased()
//                songInfo = songInfo.folding(options: .diacriticInsensitive, locale: .current)
//                if value.title.lowercased().contains(songName.lowercased()) {
//                    print("contains song name")
//                }
//                // for some reason doesn't work, maybe go back to this but for now just gonna compare the song name
//                if songInfo.contains(songArtist.lowercased()) {
//                    print("contains song artist")
//                }
//                if "the show goes on by lupe fiasco".contains("lupe fiasco") {
//                    print("hell yea")
//                }
                if value.title.lowercased().contains(songName.lowercased()) {
                    print(songName.lowercased())
                    print("Found song name!")
                    return value.lyrics
                }

            }
            // if it reaches this point then that means it is not able to find lyrics
            return "No lyrics found"
        }
        catch {
            print(error)
            return nil
        }
    }
}


