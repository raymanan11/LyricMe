//
//  MainViewController.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/17/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    var currentlyPlaying = CurrentlyPlayingManager()
    var lyricManager = LyricManager()

    @IBOutlet weak var lyrics: UITextView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    @IBOutlet weak var albumImage: UIImageView!
    
    @IBOutlet weak var topLyricLabel: UILabel!
    @IBOutlet weak var bottomLyricLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        self.lyrics.isHidden = true
        // creates the circle image of the logo/currently playing album
        self.albumImage.layer.cornerRadius = self.albumImage.frame.height / 2
        self.albumImage.clipsToBounds = true
        self.albumImage.layer.borderWidth = 4
        // change the color to match the occasion (whether a button or dark/light mode)
        self.albumImage.layer.borderColor = UIColor.black.cgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.getInfo), name: NSNotification.Name(rawValue: Constants.newAccessToken), object: nil)
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        currentlyPlaying.UIDelegate = self
        lyricManager.delegate = self
        currentlyPlaying.fetchData()
    }
    
    @IBAction func getCurrentlyPlaying(_ sender: Any) {
        currentlyPlaying.fetchData()
    }
    
    @objc func getInfo() {
        currentlyPlaying.fetchData()
    }
    
}

extension MainViewController: LyricManagerDelegate {
    
    // updates the UI to show lyrics for song
    func updateLyrics(_ fullLyrics: String) {
        DispatchQueue.main.async {
            self.lyrics.text = fullLyrics
            self.lyrics.scrollRangeToVisible(NSMakeRange(0, 0))
            LyricManager.triedOnce = false
            print("Got the lyrics and updating it!")
        }
    }
}

extension MainViewController: UI {
    
    func updateSpotifyStatus(isPlaying: Bool) {
        DispatchQueue.main.async {
            self.lyrics.isHidden = true
            self.albumImage.image = UIImage(named: "LyricallyLogo")
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
            self.lyrics.isHidden = false
            self.songTitle.text = songInfo.songName
            self.songArtist.text = "by " + songInfo.allArtists
            print("All artists: \(songInfo.allArtists)")
            self.updateAlbumImage(albumURL: songInfo.albumURL)
            self.lyrics.text = "Getting Lyrics..."
            print("Got the currently playing info and updated it!")
        }
    }
    
    func updateAlbumImage(albumURL: String) {
        if let url = URL(string: albumURL) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        self.albumImage.image = UIImage(data: data)
                    }
                }
            }
            task.resume()
        }
    }
}

