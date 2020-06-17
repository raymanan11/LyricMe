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
    
    func getArtistInfo(id: String) {
        if let accesstoken = KeychainWrapper.standard.string(forKey: Constants.accessToken) {
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accesstoken)"]
            let parameters = ["country": "US"]
            print(id)
            AF.request("https://api.spotify.com/v1/artists/\(id)/top-tracks?", method: .get, parameters: parameters, headers: headers).responseJSON { response in
                if let info = self.parseJSON(songData: response.data!) {
                    self.delegate?.getArtist(info: info)
                }
            }
        }
    }
    
    func parseJSON(songData: Data) -> ArtistInfo? {
        let decoder = JSONDecoder()
        var songs = [String]()
        var songURI = [String]()
        var songAlbumImage = [String]()
        do {
            let info = try decoder.decode(SpotifyArtistInfo.self, from: songData)
            let artistName = info.tracks[0].album.artists[0].name
            for track in info.tracks {
                songs.append(track.name)
                songURI.append(track.uri)
                songAlbumImage.append(track.album.images[0].url)
            }
            let artistInfo = ArtistInfo(artistName: artistName, songAlbumImage: songAlbumImage, popularSongs: songs, songURI: songURI)
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
