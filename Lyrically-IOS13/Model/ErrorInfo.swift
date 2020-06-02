//
//  ErrorInfo.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/28/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct ErrorInfo: Decodable {
    var error: Errors
}

struct Errors: Decodable {
    var status: Int?
    var message: String?
}
