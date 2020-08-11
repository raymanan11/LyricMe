//
//  TrackInfo.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 8/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct TrackInfo: Decodable {
    var album: TrackAlbum
}

struct TrackAlbum: Decodable {
    var images: [TrackImage]?
}

struct TrackImage: Decodable {
    var url: String?
}
