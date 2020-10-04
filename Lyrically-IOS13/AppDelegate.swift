//
//  AppDelegate.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.


import UIKit
import GoogleMobileAds
import SwiftKeychainWrapper
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("appDelegate method")
        initializeNumSongsPassed()
        print("ads enabled")
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
    
    private func initializeNumSongsPassed() {
        let numSongsPassed = KeychainWrapper.standard.integer(forKey: Constants.MainVC.numSongsPassed)
        if numSongsPassed == nil {
            KeychainWrapper.standard.set(1, forKey: Constants.MainVC.numSongsPassed)
        }
    }
    
}
