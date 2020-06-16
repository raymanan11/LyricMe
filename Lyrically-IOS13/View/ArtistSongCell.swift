//
//  ArtistSongTableViewCell.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 6/9/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import UIKit

class ArtistSongCell: UITableViewCell {

//    @IBOutlet weak var albumImage: UIImageView!
//    @IBOutlet weak var songName: UILabel!
//    @IBOutlet weak var playButton: UIButton!
    
    
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
        myView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        myView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
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
//        label.text = "Dummy Label"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black

        return label
    }()

    let albumImage: UIImageView = {

        let imageView = UIImageView()
        imageView.backgroundColor = .red
//        imageView.image = UIImage(named: "yourImage")?.withRenderingMode(.alwaysOriginal)
        imageView.translatesAutoresizingMaskIntoConstraints  = false
        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true

        return imageView
    }()
    
    @objc fileprivate func handlePlay() {
        print("Play...")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .white

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
        fatalError("init(coder:) has not been implemented")
    }
    
}
