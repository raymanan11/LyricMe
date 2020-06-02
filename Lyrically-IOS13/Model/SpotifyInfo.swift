//
//  SpotifyInfo.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/17/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct SpotifyInfo: Decodable {
    var item: Item?
}

struct Item: Decodable {
    var name: String?
    var album: Album?
    var artists: [Artist]
}

struct Album: Decodable {
    var images: [Images]
}

struct Images: Decodable {
    var url: String?
}

struct Artist: Decodable {
    var name: String?
}
