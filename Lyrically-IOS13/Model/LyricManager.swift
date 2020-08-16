//
//  LyricManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import Alamofire

protocol LyricManagerDelegate : class {
    func updateLyrics(_ fullLyrics: String)
}

class LyricManager {
    var songName = ""
    var songArtist = ""
    
    var delegate: LyricManagerDelegate?
    
    var triedOnce: Bool = false
    static var triedMultipleArtists: Bool = false
    var triedSingleArtist: Bool = false
    
    let lyricsOVH = "https://api.lyrics.ovh/v1/"
    
    var dataTask: URLSessionDataTask?
    
    var previousSong: String?
    
    func fetchData(songAndArtist: String, songName: String, songArtist: String) {
        let songNames = songName.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let songArtists = songArtist.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if songName != previousSong {
            previousSong = songName
            if let safeSongName = songNames, let safeSongArtist = songArtists {
                let url = URL(string: "\(lyricsOVH)\(safeSongArtist)/\(safeSongName)")!
                let request = URLRequest(url: url)

                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let safeData = data {
                        if let lyrics = self.parseJson(safeData) {
                            self.delegate?.updateLyrics(lyrics)
                            self.triedSingleArtist = false
                            self.triedOnce = false
                            self.previousSong = nil
                        }
                    }
                    else {
                        print(error ?? "Unknown error")
                    }
                }
                task.resume()
            }
            else {
                delegate?.updateLyrics(Constants.noLyrics)
            }
        }

    }
    
    func parseJson(_ safeData: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let str = String(decoding: safeData, as: UTF8.self)
            print(str)
            let songInfo = try decoder.decode(LyricsOVHInfo.self, from: safeData)
            if let lyrics = songInfo.lyrics {
                let parsedlyrics = parseLyrics(lyrics)
                return parsedlyrics
            }
            // if it reaches this point then that means it is not able to find lyrics
            return Constants.noLyrics
        }
        catch {
            print(error)
            return Constants.noLyrics
        }
    }
    
    func parseLyrics(_ lyrics: String) -> String {
        if lyrics.contains("\r\n") {
            return lyrics.replacingOccurrences(of: "\n\n", with: "\n")
        }
        return lyrics
    }
    
    func parseWord(_ word: String) -> String {
        return word.replacingOccurrences(of: "&", with: "and").folding(options: .diacriticInsensitive, locale: .current).filter { !$0.isWhitespace && !"/-.,'’".contains($0) }
    }

}


