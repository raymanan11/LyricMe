//
//  SongInfo.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct CanaradoSongInfo :Decodable {
    var content: [Content]
}

struct Content: Decodable {
    var title: String
    var lyrics: String
    var artist: String
}
