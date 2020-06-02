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
    
    var tokenManager = TokenManager()
    
    var UIDelegate: UI?
    
    // gets the information of the currently playing song and artist
    @objc func fetchData() {
        let accessToken: String? = KeychainWrapper.standard.string(forKey: Constants.accessToken)
        
        print("Access token is: \(accessToken ?? "none")")

        let headers = ["Authorization" : "Bearer \(accessToken ?? "none")"]
        
//        accessToken = KeychainWrapper.standard.string(forKey: Constants.accessToken)!
        
        //print("Using access token: \(accessToken)")
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.spotify.com/v1/me/player/currently-playing")! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: handle(data:response:error:))
        dataTask.resume()
    }
    
    func handle(data: Data?, response: URLResponse?, error: Error?) {
        if error != nil {
            print(error!)
            return
        }
        else {
            if let safeData = data {
//                let sdata = String(data: safeData, encoding: String.Encoding.utf8) as String?
//                print(sdata)

                // check if the access token is expired, then if it is then refresh to get new access token and post a notification that a new refresh token was received and call fetchData again
                if self.checkError(safeData) == true {
                    
                    print("Access token is expired")
                    print("Getting new access token")
                    UIDelegate?.updateSpotifyStatus(isPlaying: true)
                    tokenManager.refreshToken()
                }
                
                else {
                    if let info = self.parseJSON(data: safeData) {
                        // update the UI that shows currently playing songs, song artist(s)
                        UIDelegate?.updateSongInfoUI(info)
                        let songAndArtist = "\(info.songName) \(info.allArtists)"
                        // pass info to Main VC which will call API to get lyrics from passed data
                        UIDelegate?.passData(songAndArtist, songName: info.songName, songArtist: info.artistName)
                    }
                    else {
                        UIDelegate?.updateSpotifyStatus(isPlaying: false)
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
            let info = try decoder.decode(SpotifyInfo.self, from: data)
            
            if let singleArtist = info.item?.artists[0].name, let songName = info.item?.name, let albumURL = info.item?.album?.images[0].url {
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
                let currentlyPlayingInfo = CurrentlyPlayingInfo(artistName: singleArtist, songName: correctSongName, allArtists: artists, albumURL: albumURL)
                return currentlyPlayingInfo
            }
            return nil
        }
        catch {
            // update the lyrics info in the main to ask to play a song
            return nil
        }
    }
    
    func checkError(_ potentialError: Data) -> Bool? {
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
                    let slicedArr = arr[0...index - 1]
                    arr = Array(slicedArr)
                    correctSongName = arr.joined(separator: " ")
                    break
                }
            }
            return correctSongName
        }
        return songName;
    }
}

