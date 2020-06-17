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
    
    // gets the information of the currently playing song and artist
    @objc func fetchData() {
        let accessToken: String? = KeychainWrapper.standard.string(forKey: Constants.accessToken)

        let headers = ["Authorization" : "Bearer \(accessToken ?? "none")"]
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.spotify.com/v1/me/player/currently-playing")! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: handle(data:response:error:))
        dataTask.resume()
    }
    
    func handle(data: Data?, response: URLResponse?, error: Error?) {
        if error != nil {
            print(error!)
            UIDelegate?.updateSpotifyStatus(isPlaying: true)
            print("Error occurred! Trying to get info again!")
            fetchData()
            return
        }
        else {
            if let safeData = data {
//                let sdata = String(data: safeData, encoding: String.Encoding.utf8) as String?
//                print(sdata)

                // check if the access token is expired, then if it is then refresh to get new access token and post a notification that a new refresh token was received and call fetchData again
                if self.expiredAccessToken(safeData) == true {
                    UIDelegate?.updateSpotifyStatus(isPlaying: true)
                    previousSong = nil
                    tokenManager.refreshToken()
                }
                
                else {
                    if let info = self.parseJSON(data: safeData) {
                        // update the UI that shows currently playing songs, song artist(s)
                        // pass info to Main VC which will call API to get lyrics from passed data
                        if info.apiSongName != previousSong {
                            UIDelegate?.updateSongInfoUI(info)
                            let songAndArtist = "\(info.apiSongName) \(info.allArtists)"
                            UIDelegate?.passData(songAndArtist, songName: info.apiSongName, songArtist: info.artistName)
                            previousSong = info.apiSongName
                        }
                    }
                    else {
                        // will reach here if no song is playing
                        UIDelegate?.updateSpotifyStatus(isPlaying: false)
                        previousSong = nil
                    }
                }
            }
        }
    }
    
    func parseJSON(data: Data) -> CurrentlyPlayingInfo? {
        let decoder = JSONDecoder()
        do {
//            if let JSONString = String(data: data, encoding: String.Encoding.utf8) {
//               print(JSONString)
//            }
            let info = try decoder.decode(SpotifyCurrentlyPlayingInfo.self, from: data)
            
            if let singleArtist = info.item?.artists[0].name, let songName = info.item?.name, let albumURL = info.item?.album?.images[0].url, let artistID = info.item?.album?.artists[0].id {
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
                let currentlyPlayingInfo = CurrentlyPlayingInfo(artistName: singleArtist, fullSongName: songName, apiSongName: correctSongName, allArtists: artists, albumURL: albumURL, isPlaying: info.is_playing, artistID: artistID)
                return currentlyPlayingInfo
            }
            return nil
        }
        catch {
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
        if songName.contains("(") || songName.contains("-") {
            var arr = songName.components(separatedBy: " ")
            var correctSongName = ""
            for(index, value) in arr.enumerated() {
                if value.contains("(") || value.contains("-") {
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

