//
//  SpotifyArtistPicture.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 6/7/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct SpotifyArtistInfo2: Decodable {
    var followers: Followers
    var images: [ArtistImage]
    var name: String
}

struct Followers: Decodable {
    var total: Int
}

struct ArtistImage: Decodable {
    var height: Int
    var width: Int
    var url: String
}
