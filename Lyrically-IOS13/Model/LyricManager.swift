//
//  LyricManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

protocol LyricManagerDelegate : class {
    func updateLyrics(_ fullLyrics: String)
}

class LyricManager {
    
    var songName = ""
    var singleSongArtist = ""
    var multipleSongArtists = ""

    var delegate: LyricManagerDelegate?

    static var triedMultipleArtists: Bool = false
    var triedLyricsOVH: Bool = false
    var triedKSoft = false
    
    let lyricsOVH = "https://api.lyrics.ovh/v1/"
    let ksoft = "https://api.ksoft.si/lyrics/search"
    
    var dataTask: URLSessionDataTask?
    
    let spotifyInstalled: Bool? = KeychainWrapper.standard.bool(forKey: Constants.spotifyInstalled)
    
    func fetchData(songAndArtist: String, songName: String, singleSongArtist: String, multipleSongArtists: String) {
        self.songName = songName
        self.singleSongArtist = singleSongArtist
        self.multipleSongArtists = multipleSongArtists

        let spotifySongName = songName.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let singleSpotifySongArtist = singleSongArtist.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let multSongArtists = multipleSongArtists.replacingOccurrences(of: "’", with: "'").replacingOccurrences(of: "/", with: "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        print("LyricManager fetchData")
        if let safeSongName = spotifySongName, let safeMultSongArtist = multSongArtists, let safeSingleArtist = singleSpotifySongArtist {
            var url: URL
            var request: URLRequest

            if !triedKSoft {
                let fullURL = "\(ksoft)?q=\(safeSongName)%20\(safeMultSongArtist)"
                url = URL(string: fullURL)!
                request = URLRequest(url: url)
                request.setValue("Bearer \(Constants.ksoftAPIKey)", forHTTPHeaderField: "Authorization")
            }
            else {
                url = URL(string: "\(lyricsOVH)\(safeSingleArtist)/\(safeSongName)")!
                request = URLRequest(url: url)
            }

            getLyrics(request, triedKSoft: triedKSoft)
        }
        else {
            delegate?.updateLyrics(Constants.noLyrics)
        }
        
    }
    
    func getLyrics(_ request: URLRequest, triedKSoft: Bool) {
        let songAndSingleArtist = "\(songName) \(singleSongArtist)"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let safeData = data {
                if let lyrics = self.parseJson(safeData, triedKSoft: triedKSoft) {
                    if lyrics == Constants.noLyrics && !LyricManager.triedMultipleArtists {
                        LyricManager.triedMultipleArtists = true
                        self.fetchData(songAndArtist: songAndSingleArtist, songName: self.songName, singleSongArtist: self.singleSongArtist, multipleSongArtists: self.multipleSongArtists)
                    }
                    else {
                        self.delegate?.updateLyrics(lyrics)
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
//            let str = String(decoding: safeData, as: UTF8.self)
            // depending on boolean on which API to choose, decode from the respective class
            if !triedKSoft {
                let songInfo = try decoder.decode(KSoftInfo.self, from: safeData)
                if songInfo.data.count > 0 {
                    for songs in songInfo.data {
                        let strippedAPISongName = songs.name.folding(options: .diacriticInsensitive, locale: nil).lowercased()
                        let strippedSongName = self.songName.folding(options: .diacriticInsensitive, locale: nil).lowercased()
                        let strippedAPISongArtist = songs.artist.replacingOccurrences(of: "&", with: "and").folding(options: .diacriticInsensitive, locale: nil).lowercased()
                        let strippedSingleSongArtist = self.singleSongArtist.replacingOccurrences(of: "&", with: "and").folding(options: .diacriticInsensitive, locale: nil).lowercased()
                        print("API song name: \(strippedAPISongName)")
                        print("Spotify song name: \(strippedSongName)")
                        print("API song artist: \(strippedAPISongArtist)")
                        print("Spotify song name: \(strippedSingleSongArtist)")
                        if strippedAPISongName.contains(strippedSongName) && strippedAPISongArtist.contains(strippedSingleSongArtist) {
                            return addKSoftCredit(lyrics: songs.lyrics)
                        }

                        self.triedKSoft = true
                    }
                }
            }
            else {
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
