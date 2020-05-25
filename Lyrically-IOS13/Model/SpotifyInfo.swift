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
//
//struct Album: Decodable {
//    var artists: [Artist]
//}

struct Item: Decodable {
    var name: String?
    var artists: [Artist]
}

struct Artist: Decodable {
    var name: String?
}
