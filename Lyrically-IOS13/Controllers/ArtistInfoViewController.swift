//
//  ArtistInfoViewController.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 6/5/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import UIKit

class ArtistInfoViewController: UIViewController {

    var artistInfo: ArtistInfo?
    
    var artistImageURL: String?
    var numberOfFollowers: Int?
    var nameOfArtist: String?
    var albumPhotosURL: [String]?
    var popularSongs: [String]?
    var songURI: [String]?
    var canPlayOnDemand: Bool?
    
    let cellId = "ArtistSong"
    let tableView = UITableView()
    
    let containerView = UIView()
    let artistImage = UIImageView()
    let artistLabel = UILabel()

    var clickedSongURI: String?
    
    private var playerState: SPTAppRemotePlayerState?
    private var subscribedToPlayerState: Bool = false
    private var subscribedToCapabilities: Bool = false
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(returnToVC), name: NSNotification.Name("playButtonPressed"), object: nil)
        if let safeNumFollowers = numberOfFollowers {
            let followers = addCommas(safeNumFollowers)
            artistLabel.text = "\(nameOfArtist!)\n\nFollowers: \(followers)"
        }
        artistLabel.font = .systemFont(ofSize: 23, weight: .semibold)
        artistLabel.numberOfLines = 0
        artistLabel.textColor = .label
        
        setArtistImage(artistImageURL: artistImageURL!, imageView: artistImage, artist: true)
        // affects artist image size
        artistImage.widthAnchor.constraint(equalToConstant: 120).isActive = true
        artistImage.heightAnchor.constraint(equalToConstant: 120).isActive = true
        artistImage.contentMode = .scaleAspectFill
        artistImage.translatesAutoresizingMaskIntoConstraints = false

//        containerView.backgroundColor = .quaternarySystemFill
        containerView.backgroundColor = UIColor(named: "AppBackground")
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(ArtistSongCell.self, forCellReuseIdentifier: cellId)
        
        view.addSubview(containerView)
        containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        // set's how big artist info is
        containerView.heightAnchor.constraint(equalToConstant: 150).isActive = true

        let stackView = UIStackView(arrangedSubviews: [artistImage, artistLabel])
        stackView.axis = .horizontal
        stackView.spacing = 15
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)
        // affects artist image size
        stackView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10).isActive = true
        stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20).isActive = true
        stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true

        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("playButtonPressed"), object: nil)
    }
    
    func setArtistImage(artistImageURL: String, imageView: UIImageView, artist: Bool) {
        if let url = URL(string: artistImageURL) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        imageView.image = UIImage(data: data)
                        if artist {
                            imageView.layer.cornerRadius = 60
                        }
                        else {
                            imageView.layer.cornerRadius = imageView.frame.height / 2
                        }
                        imageView.clipsToBounds = true
                        // change the color to match the occasion (whether a button or dark/light mode)
                        imageView.layer.borderColor = UIColor.white.cgColor
                    } 
                }
            }
            task.resume()
        }
    }
    
    func updateSongURI(songURI: String) {
        // if user doesn't have premium, use the currentSongURI and use the .play and asRadio as true
        clickedSongURI = songURI
        if let safeURI = clickedSongURI {
            appRemote?.playerAPI?.play(safeURI, callback: defaultCallback)
        }
        print("Current song uri: \(clickedSongURI ?? "nothing")")
    }

    @objc func returnToVC() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    func addCommas(_ numberOfFollowers: Int) -> String {
        var numFollowers = String(numberOfFollowers)
        var count = numFollowers.count
        let threePlaces = 3
        
        while count > threePlaces {
            count = count - threePlaces
            numFollowers.insert(",", at: numFollowers.index(numFollowers.startIndex, offsetBy: count))
        }
        return numFollowers
    }
    
}

extension ArtistInfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numRows = popularSongs?.count ?? 0
        return numRows
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArtistSong", for: indexPath) as! ArtistSongCell
        print("here")
        if let safeAlbumPhotosURL = albumPhotosURL, let safePopularSongs = popularSongs, let safeSongURI = songURI {
            ableToPlayArtistSong(cell, indexPath, safeSongURI)
            setArtistImage(artistImageURL: safeAlbumPhotosURL[indexPath.row], imageView: cell.albumImage, artist: false)
            cell.songName.text = safePopularSongs[indexPath.row]
//            ableToPlayArtistSong(cell, indexPath, safeSongURI)
        }
        return cell
    }
    
    func ableToPlayArtistSong(_ cell: ArtistSongCell, _ indexPath: IndexPath, _ songURI: [String]) {
        if let safePlayOnDemand = MainViewController.playOnDemand {
            if safePlayOnDemand {
                cell.songURI = songURI[indexPath.row]
            }
        }
    }
    
//    func ableToPlayArtistSong(_ cell: ArtistSongCell, _ indexPath: IndexPath, _ songURI: [String]) {
//        if let safePlayOnDemand = canPlayOnDemand {
//            if safePlayOnDemand {
//                cell.songURI = songURI[indexPath.row]
//            }
//            else {
//                cell.buttonPlay.isHidden = true
//            }
//        }
//    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabelPadding()
        label.text = "Popular Songs"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.backgroundColor = UIColor(named: "ArtistInfo")
        label.textColor = .label
        label.textAlignment = .left
        label.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: 60)
        return label
    }

}
