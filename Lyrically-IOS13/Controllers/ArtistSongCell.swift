//
//  ArtistSongTableViewCell.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 6/9/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import UIKit

protocol UpdateSpotify {
    func exitAndUpdateSpotify(currentSongURI: String)
}

class ArtistSongCell: UITableViewCell {
    
    var songURI: String?
    var artistVC = ArtistInfoViewController()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    let containerView: UIView = {
        let myView = UIView()
        myView.translatesAutoresizingMaskIntoConstraints = false
        myView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        myView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        
        return myView
    }()

    lazy var buttonPlay: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: Constants.Assets.playButton)
        button.setBackgroundImage(image, for: .normal)
        button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    let songName: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label

        return label
    }()

    let albumImage: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor(named: Constants.Assets.artistInfo)
        imageView.translatesAutoresizingMaskIntoConstraints  = false
        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true

        return imageView
    }()
    
    @objc fileprivate func handlePlay() {
        if let safeSongURI = songURI {
            artistVC.updateSongURI(songURI: safeSongURI)
        }
        NotificationCenter.default.post(name: NSNotification.Name("cancelLyricCall"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(Constants.ArtistVC.dismissArtistVC), object: nil)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor(named: Constants.Assets.artistInfo)
        
        containerView.addSubview(buttonPlay)
        buttonPlay.heightAnchor.constraint(equalToConstant: 50).isActive = true
        buttonPlay.widthAnchor.constraint(equalToConstant: 50).isActive = true
        buttonPlay.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        buttonPlay.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true

        let stackView: UIStackView
        if let canPlayOnDemand = MainViewController.playOnDemand, canPlayOnDemand {
            stackView = UIStackView(arrangedSubviews: [albumImage, songName, containerView])
        }
        else {
            stackView = UIStackView(arrangedSubviews: [albumImage, songName])
        }
        stackView.distribution = .fillProportionally
        stackView.spacing = 25
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
