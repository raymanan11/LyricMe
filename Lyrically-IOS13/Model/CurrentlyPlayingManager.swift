//
//  CurrentlyPlayingManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/17/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

protocol PassData {
    func passData(_ songInfo: String, songName: String, songArtist: String)
    
    func updateSongInfoUI(_ songInfo: CurrentlyPlayingInfo)
}

struct CurrentlyPlayingManager {
    var delegate: PassData?
    // the first time that it comes here, the access token will be valid here but after an hour it will not be so maybe at this point check whether the access token is still valid
    // if it's not valid, use the refresh token and request for a new acces token (this is a new method) 
    let accessToken = AuthService.instance.tokenId ?? "none"
    lazy var headers = ["Authorization" : "Bearer \(accessToken)"]
    
    var songLyrics = LyricManager()
    
    mutating func fetchData() {
        let request = NSMutableURLRequest(url: NSURL(string: "https://api.spotify.com/v1/me/player/currently-playing")! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        
        request.allHTTPHeaderFields = headers
        
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: handle(data:response:error:))
        dataTask.resume()
    }
    
    func handle(data: Data?, response: URLResponse?, error: Error?) {
        if error != nil {
            print(error?.localizedDescription)
            return
        }
        else {
            if let safeData = data {
//                    let sdata = String(data: safeData, encoding: String.Encoding.utf8) as String?
//                    print(sdata)
                if let info = self.parseJSON(data: safeData) {
                    // update the UI that shows currently playing songs, song artist(s)
                    delegate?.updateSongInfoUI(info)
                    let songAndArtist = info.songName + " " + info.allArtists
                    // pass info to Main VC which will call API to get lyrics from passed data
                    delegate?.passData(songAndArtist, songName: info.songName, songArtist: info.artistName)
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
            
            if let singleArtist = info.item?.artists[0].name, let songName = info.item?.name {
                var artists = ""
                let artistInfo = info.item?.artists
                // gets all of the artists in the song
                for(index, value) in (artistInfo?.enumerated())! {
                    if index == artistInfo!.endIndex - 1
                    {
                        artists = artists + value.name!
                    }
                    else {
                        artists = artists + value.name! + ", "
                    }
                }
                // checks of the song title has any - or () which could get the wrong info from lyric API
                let correctSongName = checkSongName(songName)
                let currentlyPlayingInfo = CurrentlyPlayingInfo(artistName: singleArtist, songName: correctSongName, allArtists: artists)
                return currentlyPlayingInfo
            }
        }
        catch {
            print("Not currently playing a song!")
            return nil
        }
        return nil
    }
    
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

