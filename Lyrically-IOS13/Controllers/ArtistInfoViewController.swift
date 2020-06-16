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
    

    @IBOutlet weak var artistImage: UIImageView!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var numFollowers: UILabel!
    @IBOutlet weak var artistPopularSongs: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        artistPopularSongs.clipsToBounds = true
        artistPopularSongs.layer.cornerRadius = 17
        artistName.text = nameOfArtist
        numFollowers.text = "Followers: \(numberOfFollowers ?? 0)"
        setArtistImage(artistImageURL: artistImageURL!, imageView: artistImage)
        artistPopularSongs.delegate = self
        artistPopularSongs.dataSource = self
        artistPopularSongs.register(UINib(nibName: "ArtistSongCell", bundle: nil), forCellReuseIdentifier: "ArtistSong")
    }
    
    func setArtistImage(artistImageURL: String, imageView: UIImageView) {
        if let url = URL(string: artistImageURL) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        imageView.image = UIImage(data: data)
                        imageView.layer.cornerRadius = imageView.frame.height / 2
                        imageView.clipsToBounds = true
                        imageView.layer.borderWidth = 2
                        // change the color to match the occasion (whether a button or dark/light mode)
                        imageView.layer.borderColor = UIColor.white.cgColor
                    } 
                }
            }
            task.resume()
        }
    }

}

extension ArtistInfoViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return popularSongs?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArtistSong", for: indexPath) as! ArtistSongCell
        setArtistImage(artistImageURL: albumPhotosURL![indexPath.row], imageView: cell.albumImage)
        cell.songName.text = popularSongs![indexPath.row]
        return cell
    }

}
