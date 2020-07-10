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
    
    let cellId = "ArtistSong"
    let tableView = UITableView()
    
    let containerView = UIView()
    let artistImage = UIImageView()
    let artistLabel = UILabel()

    var currentSongURI: String?
    
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
        
        artistLabel.text = "\(nameOfArtist!)\n\nFollowers: \(numberOfFollowers!)"
        artistLabel.font = .systemFont(ofSize: 19, weight: .semibold)
        artistLabel.numberOfLines = 0
        artistLabel.textColor = .label
        
        setArtistImage(artistImageURL: artistImageURL!, imageView: artistImage, artist: true)
        // affects artist image size
        artistImage.widthAnchor.constraint(equalToConstant: 120).isActive = true
        artistImage.heightAnchor.constraint(equalToConstant: 120).isActive = true
        artistImage.contentMode = .scaleAspectFill
        artistImage.translatesAutoresizingMaskIntoConstraints = false

        print("Album image height: \(artistImage.frame.height)")
        print("Album image width: \(artistImage.frame.width)")
        print("Album image corner radius: \(artistImage.layer.cornerRadius)")

        containerView.backgroundColor = .darkGray
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
        stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15).isActive = true
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
                        print(imageView.frame.height)
                        print(imageView.layer.cornerRadius)
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
        currentSongURI = songURI
        if let safeURI = currentSongURI {
            appRemote?.playerAPI?.play(safeURI, callback: defaultCallback)
        }
        print("Current song uri: \(currentSongURI ?? "nothing")")
    }

    @objc func returnToVC() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
}

extension ArtistInfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return popularSongs?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArtistSong", for: indexPath) as! ArtistSongCell
        setArtistImage(artistImageURL: albumPhotosURL![indexPath.row], imageView: cell.albumImage, artist: false)
        cell.songName.text = popularSongs![indexPath.row]
        // set the song URI for the song that the cell has
        cell.songURI = songURI![indexPath.row]
        return cell
    }

}
