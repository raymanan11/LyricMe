//
//  ArtistSongTableViewCell.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 6/9/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import UIKit

class ArtistSongCell: UITableViewCell {

    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let padding = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        bounds = bounds.inset(by: padding)
    }
    
}
