//
//  MainViewController.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/17/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import UIKit

protocol ArtistData {
    func passData(artistData: ArtistInfo)
}

class MainViewController: UIViewController, HasLyrics {
    
    var delegate: ArtistData?

    var currentlyPlaying = CurrentlyPlayingManager()
    var lyricManager = LyricManager()
    var spotifyArtistManager = SpotifyArtistManager()
    var spotifyArtistImageManager = SpotifyArtistImageManager()
    
    var artistID: String?
    var artistName: String?
    
    var firstSong: CurrentlyPlayingInfo?
    var spotifyArtist: ArtistInfo?
    var spotifyArtist2: ArtistInfo2?

    @IBOutlet weak var lyrics: UITextView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    @IBOutlet weak var artistInfo: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        currentlyPlaying.UIDelegate = self
        lyricManager.delegate = self
        spotifyArtistManager.delegate = self
        spotifyArtistImageManager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        self.lyrics.isHidden = true
        artistInfo.isEnabled = false
        // creates the circle image of the logo/currently playing album
        self.artistInfo.layer.cornerRadius = self.artistInfo.frame.height / 2
        self.artistInfo.clipsToBounds = true
        self.artistInfo.layer.borderWidth = 4
        // change the color to match the occasion (whether a button or dark/light mode)
        self.artistInfo.layer.borderColor = UIColor.white.cgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.getInfo), name: NSNotification.Name(rawValue: Constants.newAccessToken), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.getInfo), name: NSNotification.Name(rawValue: Constants.returnToApp), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.getSpotifyArtist), name: NSNotification.Name(rawValue: "getSpotifyArtist"), object: nil)
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("View will disappear and removing observer")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.newAccessToken), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.returnToApp), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "getSpotifyArtist"), object: nil)
    }
    
    @IBAction func getArtistInfo(_ sender: UIButton) {
        
        let artistInfo: ArtistInfoViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "artistInfo") as! ArtistInfoViewController
        artistInfo.nameOfArtist = self.spotifyArtist?.artistName
        artistInfo.albumPhotosURL = self.spotifyArtist?.songAlbumImage
        artistInfo.popularSongs = self.spotifyArtist?.popularSongs
        artistInfo.songURI = self.spotifyArtist?.songURI
        artistInfo.artistImageURL = self.spotifyArtist2?.artistImageURL
        artistInfo.numberOfFollowers = self.spotifyArtist2?.numFollowers
        
        self.present(artistInfo, animated: true, completion: nil)
        print("Getting artist data")
        
    }
    
    @objc func getInfo() {
        currentlyPlaying.fetchData()
    }
    
    @objc func getSpotifyArtist() {
        print("got spotify aritst info, picture and number of followers")
        if let safeArtistID = artistID, let safeArtistName = artistName {
            print("Artist name to be used for accuracy: \(safeArtistName)")
            // add in the artist name received by API call to currently playing info
            spotifyArtistManager.getArtistInfo(id: safeArtistID, artistName: safeArtistName)
            spotifyArtistManager.getArtistPicture(id: safeArtistID)
        }
    }
    
    func getFirstSong(firstSong: CurrentlyPlayingInfo) {
        self.firstSong = firstSong
        getFirstSongAlbumURL()
    }

    func getFirstSongAlbumURL() {
        print("in getFirstSongAlbumURL")
        if firstSong != nil {
            spotifyArtistImageManager.getArtistImageURL(id: firstSong!.artistID!)
            DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
                print("trying to get info again!")
                self.currentlyPlaying.updateSongInfo(info: self.firstSong!)
            }
        }
        else {
            print("first song is nil")
        }
    }
    
}

extension MainViewController: ReceiveArtist {
    func getArtist(info: ArtistInfo) {
        self.spotifyArtist = info
    }
    
    func getArtistPicture(info: ArtistInfo2) {
        self.spotifyArtist2 = info
    }
}

extension MainViewController: LyricManagerDelegate {
    
    // updates the UI to show lyrics for song
    func updateLyrics(_ fullLyrics: String) {
        DispatchQueue.main.async {
            self.lyrics.text = fullLyrics
            self.lyrics.scrollRangeToVisible(NSMakeRange(0, 0))
            LyricManager.triedOnce = false
        }
    }
}

extension MainViewController: UI {
    
    func updateSpotifyStatus(isPlaying: Bool) {
        DispatchQueue.main.async {
            self.lyrics.isHidden = true
            self.artistInfo.setImage(UIImage(named: "LyricallyLogo"), for: .normal)
            self.songArtist.font = UIFont(name: "Futura-Bold", size: 24)
            if isPlaying {
                self.songTitle.text = "Getting Currently"
                self.songArtist.text = "Playing Song..."
            }
            else {
                self.songTitle.text = "Please Play"
                self.songArtist.text = "A Song"
            }
        }
    }
    
    // goes to Lyric API to get info for lyrics
    func passData(_ songInfo: String, songName: String, songArtist: String) {
        lyricManager.fetchData(songAndArtist: songInfo, songName: songName, songArtist: songArtist)
    }
    
    func updateSongInfoUI(_ songInfo: CurrentlyPlayingInfo) {
        DispatchQueue.main.async {
            print("in updateSongInfoUI")
            print("Song artist: \(songInfo.artistName)")
            self.artistName = songInfo.artistName
            self.artistInfo.isEnabled = true
            self.lyrics.isHidden = false
            self.lyrics.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
            self.songTitle.text = songInfo.fullSongName
            self.songArtist.font = UIFont(name: "Futura-Medium", size: 22)
            self.songArtist.text = "by \(songInfo.allArtists)"
            self.updateAlbumImage(albumURL: songInfo.albumURL)
            self.lyrics.text = "Getting Lyrics..."
            if songInfo.artistID != nil {
                print("Artist ID is not nil: \(songInfo.artistID)")
                self.artistID = songInfo.artistID
                NotificationCenter.default.post(name: NSNotification.Name("getSpotifyArtist"), object: nil)
            }
            else {
                print("No artist ID!")
            }
        }
    }
     
    func updateAlbumImage(albumURL: String) {
        if let url = URL(string: albumURL) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        self.artistInfo.setImage(UIImage(data: data), for: .normal)
                    }
                }
            }
            task.resume()
        }
    }
    
}

extension MainViewController: FirstSong {
    func setAlbumURL(albumURL: String) {
        print("in setAlbumURL")
        if firstSong != nil {
            firstSong!.albumURL = albumURL
        }
    }
}

public extension Int {
    
    var seconds: DispatchTimeInterval {
        return DispatchTimeInterval.seconds(self)
    }
    
    var second: DispatchTimeInterval {
        return seconds
    }
    
    var milliseconds: DispatchTimeInterval {
        return DispatchTimeInterval.milliseconds(self)
    }
    
    var millisecond: DispatchTimeInterval {
        return milliseconds
    }
    
}

public extension DispatchTimeInterval {
    var fromNow: DispatchTime {
        return DispatchTime.now() + self
    }
}

