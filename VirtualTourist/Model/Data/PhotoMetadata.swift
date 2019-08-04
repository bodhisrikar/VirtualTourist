//
//  PhotoMetadata.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/28/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import Foundation

struct PhotoMetadata: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
