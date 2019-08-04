//
//  PhotosForLocation.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/24/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import Foundation

struct PhotosForLocation: Codable {
    let currentPageNumber: Int
    let totalNumberOfPages: Int
    let photosPerPage: Int
    let total: String
    let photoMetadata: [PhotoMetadata]
    
    enum CodingKeys: String, CodingKey {
        case currentPageNumber = "page"
        case totalNumberOfPages = "pages"
        case photosPerPage = "perpage"
        case total = "total"
        case photoMetadata = "photo"
    }
}
