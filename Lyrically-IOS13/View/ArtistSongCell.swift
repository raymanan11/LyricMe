//
//  ArtistSongTableViewCell.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 6/9/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import UIKit

class ArtistSongCell: UITableViewCell {
    
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
        let image = UIImage(systemName: "play.circle")
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
        imageView.backgroundColor = .quaternarySystemFill
        imageView.translatesAutoresizingMaskIntoConstraints  = false
        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        // deal with the border of the album song here

        return imageView
    }()
    
    @objc fileprivate func handlePlay() {
        NotificationCenter.default.post(name: NSNotification.Name("playButtonPressed"), object: nil)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .quaternarySystemFill
        
        containerView.addSubview(buttonPlay)
        buttonPlay.heightAnchor.constraint(equalToConstant: 50).isActive = true
        buttonPlay.widthAnchor.constraint(equalToConstant: 50).isActive = true
        buttonPlay.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        buttonPlay.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true

        let stackView = UIStackView(arrangedSubviews: [albumImage, songName, containerView])
        stackView.distribution = .fillProportionally
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
