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
    func passData(_ songInfo: String, songName: String, songArtist: String)
    func updateSongInfoUI(_ songInfo: CurrentlyPlayingInfo)
}

class CurrentlyPlayingManager {
    var previousSong: String?
    
    var tokenManager = TokenManager()
    
    var UIDelegate: UI?
    
    var triedOnce = false
    
    @objc func fetchData() {
        if let accessToken = KeychainWrapper.standard.string(forKey: Constants.accessToken) {
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accessToken)"]
            AF.request("https://api.spotify.com/v1/me/player/currently-playing", method: .get, headers: headers).responseJSON { response in
                if let safeData = response.data {
                    if self.expiredAccessToken(safeData) == true {
                        self.UIDelegate?.updateSpotifyStatus(isPlaying: true)
                        self.tokenManager.refreshToken()
                    }
                    else if let info = self.parseJSON(data: safeData) {
                        self.updateSongInfo(info: info)
                    }
                    else {
                        self.UIDelegate?.updateSpotifyStatus(isPlaying: false)
                    }
                }
            }
        }
    }
    
    func updateSongInfo(info: CurrentlyPlayingInfo) {
        UIDelegate?.updateSongInfoUI(info)
        let songAndArtist = "\(info.apiSongName) \(info.allArtists)"
        UIDelegate?.passData(songAndArtist, songName: info.apiSongName, songArtist: info.artistName)
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
                let artistInfo = info.item?.artists
                // gets all of the artists in the song
                for(index, value) in (artistInfo?.enumerated())! {
                    if index == artistInfo!.endIndex - 1 {
                        artists = artists + "\(value.name!)"
                    }
                    else {
                        artists = artists + "\(value.name!), "
                    }
                }
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
    
    // this method is used to make sure song titles with characters like - and () don't affect the API call used to get lyrics
    func checkSongName(_ songName: String) -> String {
        if songName.contains("(") || songName.contains("-") || songName.contains("/"){
            var arr = songName.components(separatedBy: " ")
            var correctSongName = ""
            for(index, value) in arr.enumerated() {
                if value.contains("(") || value.contains("-") || value.contains("/"){
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
        return songName
    }

}

