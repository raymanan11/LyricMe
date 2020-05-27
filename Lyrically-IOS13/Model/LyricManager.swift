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
                    // goes back to the Main VC and updates the user interface to show the lyrics on the screen
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

            print("song name: " + songName)
            print("song artist: " + songArtist)
            print()
            for(index, value) in songInfo.content.enumerated() {
                let potentialSongName = value.title.lowercased()
                print("Song Name: " + potentialSongName)
                
//                if potentialSongName.contains(songArtist.lowercased()) {
//                    print("Found artist name: " + songArtist.lowercased())
//                }
                
                // hopefully also include an and statement that will include the artist name for extra security/accuracy to get lyrics from API like the statement above
                if potentialSongName.contains(songName.lowercased()) {
                    print("Found song name: " + songName.lowercased())

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


