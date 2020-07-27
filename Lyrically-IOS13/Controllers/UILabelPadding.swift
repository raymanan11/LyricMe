//
//  UILabelPadding.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 7/26/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation

class UILabelPadding: UILabel {

    let padding = UIEdgeInsets(top: 2, left: 25, bottom: 2, right: 25)
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize : CGSize {
        let superContentSize = super.intrinsicContentSize
        let width = superContentSize.width + padding.left + padding.right
        let heigth = superContentSize.height + padding.top + padding.bottom
        return CGSize(width: width, height: heigth)
    }

}
