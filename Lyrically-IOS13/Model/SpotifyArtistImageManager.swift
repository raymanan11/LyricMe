//
//  SpotifyArtistImageManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 7/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper

protocol FirstSong {
    func setAlbumURL(albumURL: String)
}

struct SpotifyArtistImageManager {
    
    var delegate: FirstSong?
    
    func getArtistImageURL(id: String) {
        if let accessToken = KeychainWrapper.standard.string(forKey: Constants.accessToken) {
            let headers: HTTPHeaders = ["Authorization": "Bearer \(accessToken)"]
            AF.request("https://api.spotify.com/v1/artists/\(id)", method: .get, headers: headers).responseJSON { response in
                if let safeData = response.data {
                    if let info = self.parseJSON(artistData: safeData) {
                        print(info)
                        if self.delegate != nil {
                            print("delegate is not nil")
                        }
                        else {
                            print("delegate is nil")
                        }
                        self.delegate?.setAlbumURL(albumURL: info)
                    }
                }
            }
        }
    }
    
    func parseJSON(artistData: Data) -> String? {
        let decoder = JSONDecoder()
        do {
            let info = try decoder.decode(SpotifyArtistImageInfo.self, from: artistData)
            let artistImageURL = info.images[0].url
            return artistImageURL
        }
        catch {
            print(error)
            return nil
        }
    }
}
