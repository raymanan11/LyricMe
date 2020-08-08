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
    
    let canarado = "https://api.canarado.xyz/lyrics/"
    
    var dataTask: URLSessionDataTask?
    
    var previousSong: String?
    
    func fetchData(songAndArtist: String, songName: String, songArtist: String) {
        print("in fetchData")
        self.songName = songName
        self.songArtist = songArtist

        let songURL = songAndArtist.replacingOccurrences(of: "’", with: "'").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if songName != previousSong {
            previousSong = songName
            if let safeStringURL = songURL {
                print("Getting lyrics for URL")
                getLyrics(URL: "\(canarado)\(safeStringURL)")
            }
            else {
                delegate?.updateLyrics(Constants.noLyrics)
            }
        }
        
    }
    
    func getLyrics(URL: String) {
        let songAndSingleArtist = "\(songName) \(songArtist)"
        AF.request(URL, method: .get).responseJSON { response in
            if let safeData = response.data {
//                    let str = String(decoding: safeData, as: UTF8.self)
//                    print(str)
                if let lyrics = self.parseJson(safeData) {
                    // the triedOnce variable ensures that "no lyrics found" is showed after trying an alternate method of looking for lyrics from lyric API
                    if lyrics == Constants.noLyrics && !LyricManager.triedMultipleArtists {
                        LyricManager.triedMultipleArtists = true
                        // another way of getting lyrics if not found is trying just one artist instead of all
                        print("No lyrics found for multiple artists, trying again")
                        self.previousSong = nil
                        self.triedSingleArtist = true
                        self.fetchData(songAndArtist: songAndSingleArtist, songName: self.songName, songArtist: self.songArtist)
                    }
                    else {
                        self.delegate?.updateLyrics(lyrics)
                        self.triedSingleArtist = false
                        self.triedOnce = false
                    }
                }
            }
        }
    }
    
    func parseJson(_ safeData: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let songInfo = try decoder.decode(CanaradoSongInfo.self, from: safeData)
            let spotifySongName = parseWord(songName.lowercased())
            let spotifySongArtist = parseWord(songArtist.lowercased())
            print("Spotify song name: \(spotifySongName)")
            print("Spotify song artist: \(spotifySongArtist)")
            if let lyricsOptionOne = getLyrics(songInfo, spotifySongName, spotifySongArtist) {
                print("Lyrics Option One")
                return lyricsOptionOne
            }
            else if triedSingleArtist {
                if let lyricsOptionTwo = getLyrics(songInfo, spotifySongName, nil) {
                    print("Lyrics Option Two")
                    return lyricsOptionTwo
                }
            }
            else {
                print("unable to find lyrics")
            }
            // if it reaches this point then that means it is not able to find lyrics
            return Constants.noLyrics
        }
        catch {
            print(error)
            return Constants.noLyrics
        }
    }
    
    func getLyrics(_ songInfo: CanaradoSongInfo, _ spotifySongName: String, _ spotifySongArtist: String?) -> String? {
        for(_, value) in songInfo.content.enumerated() {
            let potentialSongName = value.title.lowercased()
            let canaradoSongName = parseWord(potentialSongName)
            print("potential songs: \(canaradoSongName)")
        }
        for(_, value) in songInfo.content.enumerated() {
            let potentialSongName = value.title.lowercased()
            let canaradoSongName = parseWord(potentialSongName)
            if let safeSongArtist = spotifySongArtist {
                if canaradoSongName.contains(spotifySongName) && canaradoSongName.contains(safeSongArtist) {
                    print("Correct song name using song name and artist name: \(canaradoSongName)")
                    return value.lyrics
                }
            }
            else {
                if canaradoSongName.contains(spotifySongName) {
                    print("Correct song name not using artist name: \(canaradoSongName)")
                    return value.lyrics
                }
            }
        }
        return nil
    }
    
    func parseWord(_ word: String) -> String {
        return word.replacingOccurrences(of: "&", with: "and").folding(options: .diacriticInsensitive, locale: .current).filter { !$0.isWhitespace && !"/-.,'’".contains($0) }
    }

}


