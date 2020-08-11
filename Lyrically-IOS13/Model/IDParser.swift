//
//  IDParser.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 8/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct IDParser {
    
    func parseURI(uri: String) -> String? {
        if uri == "" {
            return nil
        }
        let parts = uri.components(separatedBy: ":")
        return parts[2]
    }
    
}
