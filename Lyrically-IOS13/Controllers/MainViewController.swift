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
    
    var updateFirstSongPic: Bool = false
    var artistID: String?
    var artistName: String?
    
    var firstSong: CurrentlyPlayingInfo?
    var spotifyArtist: ArtistInfo?
    var spotifyArtist2: ArtistInfo2?

    @IBOutlet var lyrics: UITextView!
    @IBOutlet var songTitle: UILabel!
    @IBOutlet var songArtist: UILabel!
    @IBOutlet var artistInfo: UIButton!
    @IBOutlet weak var skipForward: UIButton!
    @IBOutlet weak var skipBackward: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        currentlyPlaying.UIDelegate = self
        lyricManager.delegate = self
        spotifyArtistManager.delegate = self
        spotifyArtistImageManager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        self.skipForward.isHidden = true
        self.skipBackward.isHidden = true
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnToLogIn), name: NSNotification.Name(rawValue: "returnToLogIn"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateStatus), name: NSNotification.Name(rawValue: "updateStatus"), object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.newAccessToken), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.returnToApp), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "returnToLogIn"), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "updateStatus"), object: nil)
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
        
    }
    
    @objc func getInfo() {
        currentlyPlaying.fetchData()
    }
    
    @objc func getSpotifyArtist() {
        if let safeArtistID = artistID, let safeArtistName = artistName {
            // add in the artist name received by API call to currently playing info
            spotifyArtistManager.getArtistInfo(id: safeArtistID, artistName: safeArtistName)
            spotifyArtistManager.getArtistPicture(id: safeArtistID)
        }
    }
    
    func getFirstSong(info: CurrentlyPlayingInfo) {
        self.firstSong = info
        getFirstSongAlbumURL()
    }

    func getFirstSongAlbumURL() {
        if let _ = firstSong, let _ = firstSong?.artistID {
            DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
                self.currentlyPlaying.updateSongInfo(info: self.firstSong!)
            }
        }
        else {
            self.currentlyPlaying.UIDelegate?.updateSpotifyStatus(isPlaying: false)
        }
    }
    
    @objc func returnToLogIn() {
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func updateStatus() {
        updateSpotifyStatus(isPlaying: true)
    }
    
}

extension MainViewController: ReceiveArtist {
    
    func getArtist(info: ArtistInfo) {
        self.spotifyArtist = info
        updateFirstSongPicture(info)
    }
    
    func getArtistPicture(info: ArtistInfo2) {
        self.spotifyArtist2 = info
    }
    
    func updateFirstSongPicture(_ info: ArtistInfo) {
        if firstSong != nil && updateFirstSongPic == false {
            updateFirstSongPic = true
            for (index, trackName) in info.popularSongs.enumerated() {
                if trackName.localizedStandardContains(firstSong!.apiSongName) {
                    print("updated 1")
                    updateAlbumImage(albumURL: info.songAlbumImage[index])
                    return
                }
            }
            if let safeArtistID = artistID {
                print("updated 2")
                print("not one of the top songs so getting artist image")
                spotifyArtistImageManager.getArtistImageURL(id: safeArtistID)
            }
        }
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
            self.skipForward.isHidden = true
            self.skipBackward.isHidden = true
            self.artistInfo.isEnabled = false
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
            self.artistName = songInfo.artistName
            self.artistInfo.isEnabled = true
            self.skipForward.isHidden = false
            self.skipBackward.isHidden = false
            self.lyrics.isHidden = false
            self.lyrics.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
            self.songTitle.text = songInfo.fullSongName
            self.songArtist.font = UIFont(name: "Futura-Medium", size: 22)
            self.songArtist.text = "by \(songInfo.allArtists)"
            print("Main VC: \(songInfo.albumURL)")
            self.updateAlbumImage(albumURL: songInfo.albumURL)
            self.lyrics.text = "Getting Lyrics..."
            if songInfo.artistID != nil {
                print(songInfo.artistID)
                self.artistID = songInfo.artistID
                self.getSpotifyArtist()
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
    func updateFirstSongPicture(albumURL: String) {
        print("in here")
//        if firstSong != nil {
//            firstSong!.albumURL = albumURL
//        }
        updateAlbumImage(albumURL: albumURL)
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

