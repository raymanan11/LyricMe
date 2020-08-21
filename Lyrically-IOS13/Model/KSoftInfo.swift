//
//  KSoftInfo.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 8/17/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct KSoftInfo: Decodable {
    var data: [KSoft]
}

struct KSoft: Decodable {
    var name: String
    var artist: String
    var lyrics: String
}
