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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        currentlyPlaying.delegate = self
        lyricManager.delegate = self
        currentlyPlaying.fetchData()
    }
    
    @IBAction func getCurrentlyPlaying(_ sender: Any) {
        currentlyPlaying.fetchData()
    }
    
}

extension MainViewController: LyricManagerDelegate {
    func updateLyrics(_ fullLyrics: String) {
        DispatchQueue.main.async {
            self.lyrics.text = fullLyrics
        }
    }
}

extension MainViewController: PassData {
    func passData(_ songInfo: String, songName: String, songArtist: String) {
        lyricManager.fetchData(songAndArtist: songInfo, songName: songName, songArtist: songArtist)
    }
    
    func updateSongInfoUI(_ songInfo: CurrentlyPlayingInfo) {
        DispatchQueue.main.async {
            self.songTitle.text = songInfo.songName
            self.songArtist.text = "by " + songInfo.allArtists
        }
    }
}

