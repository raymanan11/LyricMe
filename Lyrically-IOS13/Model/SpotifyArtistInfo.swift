//
//  ArtistInfoManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 6/5/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

struct SpotifyArtistInfo: Decodable {
    var tracks: [Track]
}

struct Track: Decodable {
    // used to get the name of the artist
    var album: ArtistAlbum
    // name of all popular songs
    var name: String
    // popularity maybe used to order the songs
    var popularity: Int
    var uri: String
}

struct ArtistAlbum: Decodable {
    var artists: [CurrentArtist]
    var images: [AlbumImage]
}

struct CurrentArtist: Decodable {
    var name: String
}

struct AlbumImage: Decodable {
    var height: Int
    var width: Int
    var url: String
}
