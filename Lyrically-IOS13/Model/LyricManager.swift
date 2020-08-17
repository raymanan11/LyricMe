//
//  LyricManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

//import Foundation
//import Alamofire
//
//protocol LyricManagerDelegate : class {
//    func updateLyrics(_ fullLyrics: String)
//}
//
//class LyricManager {
//    var songName = ""
//    var songArtist = ""
//
//    var delegate: LyricManagerDelegate?
//
//    var triedOnce: Bool = false
//    static var triedMultipleArtists: Bool = false
//    var triedLyricsOVH: Bool = false
//
//    let lyricsOVH = "https://api.lyrics.ovh/v1/"
//    let ksoft = "https://api.ksoft.si/lyrics/search"
//
//    var dataTask: URLSessionDataTask?
//
//    var previousSong: String?
//
//    func fetchData(songAndArtist: String, songName: String, songArtist: String) {
//
//        let songNames = songName.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//        let songArtists = songArtist.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//
//        if songName != previousSong {
//            previousSong = songName
//            if let safeSongName = songNames, let safeSongArtist = songArtists {
//                var url: URL
//                var request: URLRequest
//
//                if !triedLyricsOVH {
//                    url = URL(string: "\(lyricsOVH)\(safeSongArtist)/\(safeSongName)")!
//                    request = URLRequest(url: url)
//                }
//                else {
//                    url = URL(string: ksoft)!
//                    request = URLRequest(url: url)
//                    request.setValue("wmkcgsQgrTkdvg3K1RRp9vIeP8iprYiu", forHTTPHeaderField: "Authorization")
//                }
//
//                getLyrics(request)
//            }
//            else {
//                delegate?.updateLyrics(Constants.noLyrics)
//            }
//        }
//
//    }
//
//    func getLyrics(_ request: URLRequest) {
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let safeData = data {
//                if let lyrics = self.parseJson(safeData) {
//                    self.delegate?.updateLyrics(lyrics)
//                    self.triedOnce = false
//                    self.previousSong = nil
//                }
//            }
//            else {
//                print(error ?? "Unknown error")
//            }
//        }
//        task.resume()
//    }
//
//    // add a boolean that determines which class to decode from
//    func parseJson(_ safeData: Data) -> String? {
//        let decoder = JSONDecoder()
//        do {
//            let str = String(decoding: safeData, as: UTF8.self)
//            print(str)
//            // depending on boolean on which API to choose, decode from the respective class
//            let songInfo = try decoder.decode(LyricsOVHInfo.self, from: safeData)
//            if let lyrics = songInfo.lyrics {
//                let parsedlyrics = parseLyrics(lyrics)
//                return parsedlyrics
//            }
//            // if it reaches this point then that means it is not able to find lyrics
//            return Constants.noLyrics
//        }
//        catch {
//            print(error)
//            return Constants.noLyrics
//        }
//    }
//
//    func parseLyrics(_ lyrics: String) -> String {
//        if lyrics.contains("\r\n") {
//            return lyrics.replacingOccurrences(of: "\n\n", with: "\n")
//        }
//        return lyrics
//    }
//
//    func parseWord(_ word: String) -> String {
//        return word.replacingOccurrences(of: "&", with: "and").folding(options: .diacriticInsensitive, locale: .current).filter { !$0.isWhitespace && !"/-.,'’".contains($0) }
//    }
//
//}

import Foundation
import Alamofire

protocol LyricManagerDelegate : class {
    func updateLyrics(_ fullLyrics: String)
}

class LyricManager {
    var songName = ""
    var songArtist = ""

    var delegate: LyricManagerDelegate?

    static var triedMultipleArtists: Bool = false
    var triedLyricsOVH: Bool = false
    var triedKSoft = false
    
    let lyricsOVH = "https://api.lyrics.ovh/v1/"
    let ksoft = "https://api.ksoft.si/lyrics/search"
    
    var dataTask: URLSessionDataTask?

    var previousSong: String?
    
    func fetchData(songAndArtist: String, songName: String, songArtist: String) {
        self.songName = songName
        self.songArtist = songArtist

        let songNames = songName.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let songArtists = songArtist.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if songName != previousSong {
            print("song names are different")
            previousSong = songName
            if let safeSongName = songNames, let safeSongArtist = songArtists {
                var url: URL
                var request: URLRequest
                
//                let fullURL = "\(ksoft)?q=\(safeSongName)%20\(safeSongArtist)"
//                url = URL(string: fullURL)!
//                request = URLRequest(url: url)
//                request.setValue("Bearer 66960dae4b894912db38084b7e62431df6507254", forHTTPHeaderField: "Authorization")
                
                if !triedKSoft {
                    print("Primary Lyrics")
                    let fullURL = "\(ksoft)?q=\(safeSongName)%20\(safeSongArtist)"
                    url = URL(string: fullURL)!
                    request = URLRequest(url: url)
                    request.setValue("Bearer 66960dae4b894912db38084b7e62431df6507254", forHTTPHeaderField: "Authorization")
                }
                else {
                    print("Secondary Lyrics")
                    print("\(lyricsOVH)\(safeSongArtist)/\(safeSongName)")
                    url = URL(string: "\(lyricsOVH)\(safeSongArtist)/\(safeSongName)")!
                    request = URLRequest(url: url)
                }

                getLyrics(request, triedKSoft: triedKSoft)
            }
            else {
                delegate?.updateLyrics(Constants.noLyrics)
            }
        }
        
    }
    
    func getLyrics(_ request: URLRequest, triedKSoft: Bool) {
        let songAndSingleArtist = "\(songName) \(songArtist)"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let safeData = data {
                if let lyrics = self.parseJson(safeData, triedKSoft: triedKSoft) {
                    if lyrics == Constants.noLyrics && !LyricManager.triedMultipleArtists {
                        LyricManager.triedMultipleArtists = true
                        self.previousSong = nil
                        self.fetchData(songAndArtist: songAndSingleArtist, songName: self.songName, songArtist: self.songArtist)
                    }
                    else {
                        self.delegate?.updateLyrics(lyrics)
                        self.previousSong = nil
                        self.triedKSoft = false
                    }
                }
            }
            else {
                print(error ?? "Unknown error")
            }
        }
        task.resume()
    }

    // add a boolean that determines which class to decode from
    func parseJson(_ safeData: Data, triedKSoft: Bool) -> String? {
        let decoder = JSONDecoder()
        do {
            let str = String(decoding: safeData, as: UTF8.self)
            // depending on boolean on which API to choose, decode from the respective class
            if !triedKSoft {
                let songInfo = try decoder.decode(KSoftInfo.self, from: safeData)
                if songInfo.data.count > 0 {
                    for songs in songInfo.data {
                        let strippedAPISongName = songs.name.folding(options: .diacriticInsensitive, locale: nil)
                        let strippedSongName = self.songName.folding(options: .diacriticInsensitive, locale: nil)
                        if strippedAPISongName.contains(strippedSongName) {
                            print("API song name: \(strippedAPISongName)")
                            print("Spotify song name: \(songs.name)")
                            return songs.lyrics
                        }
                        self.triedKSoft = true
                    }
                }
            }
            else {
                print("Already tried KSoft")
                let songInfo = try decoder.decode(LyricsOVHInfo.self, from: safeData)
                if let lyrics = songInfo.lyrics {
                    return lyrics
                }
                print(songInfo.error)
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
