//
//  SpotifyTrackManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 8/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

protocol FirstSong {
    func updateFirstSongPicture(albumURL: String)
}

struct SpotifyTrackManager {
    
    var delegate: FirstSong?
    
    func getTrackAlbumImage(trackID: String) {
        if let accessToken = KeychainWrapper.standard.string(forKey: Constants.Tokens.accessToken) {
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accessToken)"]
            AF.request("https://api.spotify.com/v1/tracks/\(trackID)", method: .get, headers: headers).responseJSON { response in
                if let safeData = response.data {
                    if let info = self.parseJSON(trackData: safeData) {
                        self.delegate?.updateFirstSongPicture(albumURL: info)
                    }
                }
            }
        }
    }
    
    func parseJSON(trackData: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let info = try decoder.decode(TrackInfo.self, from: trackData)
            if let trackPictureURL = info.album.images?[0].url {
                return trackPictureURL
            }
        }
        catch {
            print(error)
        }
        return nil
    }
}
