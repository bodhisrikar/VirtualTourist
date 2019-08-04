//
//  PhotosForLocationResponse.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/24/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import Foundation

struct PhotosForLocationResponse: Codable {
    let photoData: PhotosForLocation
    let status : String
    
    enum CodingKeys: String, CodingKey {
        case photoData = "photos"
        case status = "stat"
    }
}
