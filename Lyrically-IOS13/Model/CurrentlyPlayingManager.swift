//
//  CurrentlyPlayingManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/17/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import Alamofire

protocol UI {
    func updateSpotifyStatus(isPlaying: Bool)
    func passData(_ songInfo: String, songName: String, singleSongArtist: String, multipleSongArtists: String)
    func updateSongInfoUI(_ songInfo: CurrentlyPlayingInfo)
}

class CurrentlyPlayingManager {
    
    var previousSong: String?
    
    var tokenManager = TokenManager()
    
    var UIDelegate: UI?
    
    var lastSong: String?
    
    var triedOnce = false
    
    let spotifyInstalled: Bool? = KeychainWrapper.standard.bool(forKey: Constants.spotifyInstalled)
    
    @objc func fetchData() {
        print("getting data")
        if let accessToken = KeychainWrapper.standard.string(forKey: Constants.Tokens.accessToken) {
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accessToken)"]
            AF.request("https://api.spotify.com/v1/me/player/currently-playing", method: .get, headers: headers).responseJSON { response in
                print("About to get data")
                if let safeData = response.data {
                    if self.expiredAccessToken(safeData) == true {
                        self.UIDelegate?.updateSpotifyStatus(isPlaying: true)
                        self.tokenManager.refreshToken()
                    }
                    else if let info = self.parseJSON(data: safeData) {
                        print("self.parseJSON")
                        if let safeSpotifyInstalled = self.spotifyInstalled, !safeSpotifyInstalled, !self.triedOnce {
                            print("baby")
                            self.updateSongInfo(info: info)
                            self.triedOnce = true
                        }
                        else if let safeSpotifyInstalled = self.spotifyInstalled, safeSpotifyInstalled {
                            print("son")
                            self.updateSongInfo(info: info)
                        }
                        else {
                            print("stuck in limbo")
                        }
                    }
                    else {
                        print("Not playing a song")
                        self.UIDelegate?.updateSpotifyStatus(isPlaying: false)
                    }
                }
                else {
                    print("Not able to get data")
                    print(response.data)
                    self.UIDelegate?.updateSpotifyStatus(isPlaying: false)
                }
            }
        }
        else {
            print("not valid access token")
        }
    }
    
    func updateSongInfo(info: CurrentlyPlayingInfo) {
        // pass to the Main VC to update the Main VC to get ready for lyrics as well as put the song name, song picture, and artist info
        UIDelegate?.updateSongInfoUI(info)
        let songAndArtist = "\(info.apiSongName) \(info.allArtists)"
        // pass to main VC in order to call lyric manager to get lyrics and update the main VC with the lyrics
        UIDelegate?.passData(songAndArtist, songName: info.apiSongName, singleSongArtist: info.artistName, multipleSongArtists: info.allArtists)
    }
    
    func parseJSON(data: Data) -> CurrentlyPlayingInfo? {
        let decoder = JSONDecoder()
        do {
//            if let JSONString = String(data: data, encoding: String.Encoding.utf8) {
//               print(JSONString)
//            }
            let info = try decoder.decode(SpotifyCurrentlyPlayingInfo.self, from: data)
            
            if let singleArtist = info.item?.artists[0].name, let songName = info.item?.name, let albumURL = info.item?.album?.images[0].url, let artistID = info.item?.artists[0].id, let currentSongURI = info.item?.uri {
                var artists = ""
                if songName != lastSong {
                    lastSong = songName
                    triedOnce = false
                }
                getArtists(info, &artists)
                // checks of the song title has any - or () which could get the wrong info from lyric API
                let correctSongName = checkSongName(songName)
                let currentlyPlayingInfo = CurrentlyPlayingInfo(artistName: singleArtist, fullSongName: songName, apiSongName: correctSongName, allArtists: artists, albumURL: albumURL, artistID: artistID, currentSongURI: currentSongURI)
                return currentlyPlayingInfo
            }
            return nil
        }
        catch {
            print(error)
            NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
            return nil
        }
    }
    
    func getArtists(_ info: SpotifyCurrentlyPlayingInfo, _ artists: inout String) {
        // gets all of the artists in the song
        if let artistInfo = info.item?.artists {
            for(index, value) in (artistInfo.enumerated()) {
                if index == artistInfo.endIndex - 1 {
                    artists = artists + "\(value.name!)"
                }
                else {
                    artists = artists + "\(value.name!), "
                }
            }
        }
    }
    
    func expiredAccessToken(_ potentialError: Data) -> Bool? {
        let expireAccessTokenCode = 401
        let decoder = JSONDecoder()
        do {
            let info = try decoder.decode(ErrorInfo.self, from: potentialError)
            if info.error.status == expireAccessTokenCode {
                return true
            }
            return false
        }
        catch {
            return false
        }
    }
    
    func checkSongName(_ songName: String) -> String {
        var usedSongName = songName
        let word = songName.components(separatedBy: "(")
        let numOfParen = word.count - 1
        var sansParens = ""
        let songWithNoParen = removeParenthesis(numOfParen, &usedSongName, &sansParens)
        if songWithNoParen.contains("[") || songWithNoParen.contains("-") || songWithNoParen.contains("/"){
            var arr = songWithNoParen.components(separatedBy: " ")
            var correctSongName = ""
            for(index, value) in arr.enumerated() {
                if value.contains("[") || value.contains("-") || value.contains("/"){
                    if value.contains("-") && value.count > 1 {
                        correctSongName += value.replacingOccurrences(of: "-", with: "") + " "
                    }
                    else {
                        let slicedArr = arr[0...index - 1]
                        arr = Array(slicedArr)
                        correctSongName = arr.joined(separator: " ")
                        break
                    }
                }
                else {
                    correctSongName += value + " "
                }
            }
            return correctSongName
        }
        return songWithNoParen
    }
    
    // this method is used to make sure song titles with characters like - and () don't affect the API call used to get lyrics
    private func removeParenthesis(_ numOfParen: Int, _ usedSongName: inout String, _ sansParens: inout String) -> String {
        if numOfParen > 0 {
            for _ in 0..<numOfParen {
                if let leftIdx = usedSongName.firstIndex(of: "("), let rightIdx = usedSongName.firstIndex(of: ")") {
                    sansParens = String(usedSongName.prefix(upTo: leftIdx) + usedSongName.suffix(from: usedSongName.index(after: rightIdx)))
                    usedSongName = sansParens
                }
            }
            sansParens = sansParens.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        else {
            sansParens = usedSongName
        }
        return sansParens
    }

}

