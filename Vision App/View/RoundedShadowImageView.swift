//
//  RoundedShadowImageView.swift
//  Vision
//
//  Created by mugish on 18/10/18.
//  Copyright © 2018 Softech. All rights reserved.
//

import UIKit

class RoundedShadowImageView: UIImageView {

    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = 15
    }

}
