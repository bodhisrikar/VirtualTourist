//
//  PhotoAlbumCustomCell.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/29/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import Foundation
import UIKit

class PhotoAlbumCustomCell: UICollectionViewCell {
    @IBOutlet weak var selectedLatLongImage: UIImageView!
    @IBOutlet weak var imageOverlay: UIView!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
}

extension UIColor {
    static func customColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }
}
