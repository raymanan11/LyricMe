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
        
        isSpotifyAppActive()
        KeychainWrapper.standard.set(false, forKey: Constants.onMainVC)
        print("ads enabled")
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
    
    private func isSpotifyAppActive() {
        if (AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint) {
            print("spotify app is active")
            KeychainWrapper.standard.set(true, forKey: Constants.initiatedSession)
        }
        else {
            print("spotify app is not active")
            KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
        }
    }
    
}
