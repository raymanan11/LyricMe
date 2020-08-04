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
    var logInVC = LogInViewController()
    var alertManager = AlertManager()
    
    static var playOnDemand: Bool?
    var updateFirstSongPic: Bool = false
    var artistID: String?
    var artistName: String?
    var currentSongURI: String?
    var currentSongAlbumURL: String?
    
    var restrictions: SPTAppRemotePlaybackRestrictions?
    var firstSong: CurrentlyPlayingInfo?
    var spotifyArtist: ArtistInfo?
    var spotifyArtist2: ArtistInfo2?

    @IBOutlet var lyrics: UITextView!
    @IBOutlet var songTitle: UILabel!
    @IBOutlet var songArtist: UILabel!
    @IBOutlet var artistInfo: UIButton!
    @IBOutlet weak var skipForward: UIButton!
    @IBOutlet weak var skipBackward: UIButton!
    
    var defaultCallback: SPTAppRemoteCallback {
        get {
            return {[weak self] _, error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    var appRemote: SPTAppRemote? {
        get {
            return (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.appRemote
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        currentlyPlaying.UIDelegate = self
        lyricManager.delegate = self
        spotifyArtistManager.delegate = self
        spotifyArtistImageManager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        
        defaultMainVCUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.getInfo), name: NSNotification.Name(rawValue: Constants.Tokens.newAccessToken), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.getInfo), name: NSNotification.Name(rawValue: Constants.returnToApp), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnToLogIn), name: NSNotification.Name(rawValue: Constants.MainVC.returnToLogInVC), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateStatus), name: NSNotification.Name(rawValue: Constants.MainVC.updateStatus), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateViewWithRestrictions), name: NSNotification.Name(rawValue: Constants.MainVC.updateRestrictions), object: nil)
        
    }
    
    private func defaultMainVCUI() {
        artistInfo.isEnabled = false
        self.lyrics.isHidden = true
        self.skipForward.isHidden = true
        self.skipBackward.isHidden = true
        // creates the circle image of the logo/currently playing album
        self.artistInfo.layer.cornerRadius = self.artistInfo.frame.height / 2
        self.artistInfo.clipsToBounds = true
        self.artistInfo.layer.borderWidth = 4
        // change the color to match the occasion (whether a button or dark/light mode)
        self.artistInfo.layer.borderColor = UIColor.white.cgColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Tokens.newAccessToken), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.returnToApp), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.MainVC.returnToLogInVC), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.MainVC.updateStatus), object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.MainVC.updateRestrictions), object: nil)
    }
    
    @IBAction func getArtistInfo(_ sender: UIButton) {
        
        let artistInfo: ArtistInfoViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: Constants.StoryboardID.artistVC) as! ArtistInfoViewController
        artistInfo.nameOfArtist = self.spotifyArtist2?.name
        artistInfo.albumPhotosURL = self.spotifyArtist?.songAlbumImage
        artistInfo.popularSongs = self.spotifyArtist?.popularSongs
        artistInfo.songURI = self.spotifyArtist?.songURI
        artistInfo.artistImageURL = self.spotifyArtist2?.artistImageURL
        artistInfo.numberOfFollowers = self.spotifyArtist2?.numFollowers
        
        self.present(artistInfo, animated: true, completion: nil)
        
    }
    
    @IBAction func previousSongPressed(_ sender: Any) {
        appRemote?.playerAPI?.skip(toPrevious: defaultCallback)
    }
    
    @IBAction func nextSongPressed(_ sender: UIButton) {
        appRemote?.playerAPI?.skip(toNext: defaultCallback)
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
    
    func updateRestrictions(_ restrictions: SPTAppRemotePlaybackRestrictions) {
        self.restrictions = restrictions
    }
    
    @objc func updateViewWithRestrictions() {
        if self.restrictions != nil {
            skipForward.isEnabled = restrictions!.canSkipNext
            skipBackward.isEnabled = restrictions!.canSkipPrevious
        }
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
                    updateAlbumImage(albumURL: info.songAlbumImage[index])
                    return
                }
            }
            if let safeArtistID = artistID {
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
            self.artistInfo.setImage(UIImage(named: Constants.Assets.logo), for: .normal)
            self.artistInfo.layer.borderColor = UIColor.white.cgColor
            self.songTitle.text = ""
            self.songArtist.text = ""
            NotificationCenter.default.post(name: NSNotification.Name(Constants.ArtistVC.dismissArtistVC), object: nil)
            if !isPlaying {
                self.alertManager.presentAlert(title: "Please Play A Song", message: "Play a song to continue", vc: self)
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
            self.currentSongURI = songInfo.currentSongURI
            self.currentSongAlbumURL = songInfo.albumURL
            self.artistInfo.isEnabled = true
            self.skipForward.isHidden = false
            self.skipBackward.isHidden = false
            self.lyrics.isHidden = false
            self.lyrics.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            self.songTitle.text = songInfo.fullSongName
            let songTitleSize = self.songTitle.font.pointSize
            let songArtistSize = self.songArtist.font.pointSize
            self.songTitle.font = UIFont(name: "Futura-Bold", size: songTitleSize)
            self.songArtist.font = UIFont(name: "Futura-Medium", size: songArtistSize)
            self.songArtist.text = "by \(songInfo.allArtists)"
            self.artistInfo.layer.borderColor = UIColor(red: 14.0/255, green: 122.0/255, blue: 254.0/255, alpha: 1).cgColor
            self.updateAlbumImage(albumURL: songInfo.albumURL)
            self.lyrics.text = "Getting Lyrics..."
            if songInfo.artistID != nil {
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

