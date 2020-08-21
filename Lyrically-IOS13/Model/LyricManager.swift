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
            previousSong = songName
            if let safeSongName = songNames, let safeSongArtist = songArtists {
                var url: URL
                var request: URLRequest
                
                if !triedKSoft {
                    print("Song artist: \(safeSongArtist)")
                    let fullURL = "\(ksoft)?q=\(safeSongName)%20\(safeSongArtist)"
                    url = URL(string: fullURL)!
                    request = URLRequest(url: url)
                    request.setValue("Bearer \(Constants.ksoftAPIKey)", forHTTPHeaderField: "Authorization")
                }
                else {
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
                        let strippedAPISongName = songs.name.folding(options: .diacriticInsensitive, locale: nil).lowercased()
                        let strippedSongName = self.songName.folding(options: .diacriticInsensitive, locale: nil).lowercased()
                        let strippedAPISongArtist = songs.artist.replacingOccurrences(of: "&", with: "and").folding(options: .diacriticInsensitive, locale: nil).lowercased()
                        let strippedSongArtist = self.songArtist.replacingOccurrences(of: "&", with: "and").folding(options: .diacriticInsensitive, locale: nil).lowercased()
                        print("API song name: b\(strippedAPISongName)b")
                        print("Spotify song name: b\(strippedSongName)b")
                        if strippedSongName.contains(strippedAPISongName) && strippedSongArtist.contains(strippedAPISongArtist) {
                            print("Correct API song name: \(strippedAPISongName)")
                            print("Correct Spotify song name: \(strippedSongName)")
                            return addKSoftCredit(lyrics: songs.lyrics)
                        }
                        self.triedKSoft = true
                    }
                }
            }
            else {
                print("Already tried KSoft")
                let songInfo = try decoder.decode(LyricsOVHInfo.self, from: safeData)
                if let lyrics = songInfo.lyrics {
                    let parsedLyrics = parseLyrics(lyrics)
                    return parsedLyrics
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
    
    func addKSoftCredit(lyrics: String) -> String {
        let ksoftLyrics = "\(lyrics)\n\nLYRICS FROM api.ksoft.si"
        return ksoftLyrics
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
