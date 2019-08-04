//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/19/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataController.load()
        let navigationController = window?.rootViewController as! UINavigationController
        let travelLocationController = navigationController.topViewController as! TravelLocationsViewController
        travelLocationController.travelLocationDataController = dataController
        return true
    }
}

