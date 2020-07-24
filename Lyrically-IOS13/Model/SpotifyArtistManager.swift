//
//  SpotifyArtistManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 6/6/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

protocol ReceiveArtist {
    func getArtist(info: ArtistInfo)
    func getArtistPicture(info: ArtistInfo2)
}

struct SpotifyArtistManager {
    
    var dispatchGroup = DispatchGroup()
    var delegate: ReceiveArtist?
    var artistName: String?
    
    func getArtistInfo(id: String, artistName: String) {
        if let accessToken = KeychainWrapper.standard.string(forKey: Constants.accessToken) {
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accessToken)"]
            let parameters = ["country": "US"]
            AF.request("https://api.spotify.com/v1/artists/\(id)/top-tracks?", method: .get, parameters: parameters, headers: headers).responseJSON { response in
                if let safeData = response.data {
                    if let info = self.parseJSON(songData: safeData, artistName: artistName) {
                        self.delegate?.getArtist(info: info)
                    }
                }
            }
        }
    }
    
    func parseJSON(songData: Data, artistName: String) -> ArtistInfo? {
        let decoder = JSONDecoder()
        var songs = [String]()
        var songURI = [String]()
        var songAlbumImage = [String]()
        var correctArtistName: String?
        do {
            let info = try decoder.decode(SpotifyArtistInfo.self, from: songData)
            // check whether info from currently playing song matches info from here (loop through array to see which one matches
            // used the passed in artist name to check this
            for track in info.tracks {
                for artists in track.artists {
                    if artists.name == artistName {
                        correctArtistName = artists.name
                        songs.append(track.name)
                        // pass in can playOnDemand from getSpotifyArtist in main VC. If canPlayOnDemand is true then do this but if not don't and also hide the play button
                        songURI.append(track.uri)
                        songAlbumImage.append(track.album.images[0].url)
                        break
                    }
                }
            }
            let artistInfo = ArtistInfo(artistName: correctArtistName!, songAlbumImage: songAlbumImage, popularSongs: songs, songURI: songURI)
            return artistInfo
        }
        catch {
            print(error)
            return nil
        }
    }
    
    func getArtistPicture(id: String) {
        if let accesstoken = KeychainWrapper.standard.string(forKey: Constants.accessToken) {
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accesstoken)"]
            AF.request("https://api.spotify.com/v1/artists/\(id)", method: .get, headers: headers).responseJSON { response in
//                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
//                    print("Data: \(utf8Text)")
//                }
                if let info = self.parseJSON(artistData: response.data!) {
                    self.delegate?.getArtistPicture(info: info)
                }
            }
        }
    }
    
    func parseJSON(artistData: Data) -> ArtistInfo2? {
        let decoder = JSONDecoder()
        do {
            let info = try decoder.decode(SpotifyArtistInfo2.self, from: artistData)
            let artistInfo2 = ArtistInfo2(numFollowers: info.followers.total, artistImageURL: info.images[0].url)
            return artistInfo2
        }
        catch {
            print(error)
            return nil
        }
    }
    
    
    
}
