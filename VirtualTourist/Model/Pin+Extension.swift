//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/29/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import Foundation
import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        let lat = CLLocationDegrees(latitude)
        let long = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
}
