//
//  SpotifyInfo.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/17/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct SpotifyCurrentlyPlayingInfo: Decodable {
    var item: Item?
    var is_playing: Bool
}

struct Item: Decodable {
    var name: String?
    var album: Album?
    // used to get artist names
    var artists: [Artist]
}

struct Album: Decodable {
    var images: [Images]
    // used to get id of artist
    var artists: [Artists]
}

struct Images: Decodable {
    var url: String?
}

struct Artist: Decodable {
    var name: String?
}

struct Artists: Decodable {
    var id: String?
}
