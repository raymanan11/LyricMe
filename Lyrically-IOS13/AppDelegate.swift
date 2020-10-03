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
        isSpotifyAppActive()
        initializeNumSongsPassed()
        KeychainWrapper.standard.set(false, forKey: Constants.onMainVC)
        print("ads enabled")
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
    
    private func isSpotifyAppActive() {
            if (AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint) {
                SPTAppRemote.checkIfSpotifyAppIsActive { (isPlaying) in
                    if isPlaying {
                        print("spotify app is active")
                        KeychainWrapper.standard.set(true, forKey: Constants.initiatedSession)
                    }
                    else {
                        print("audio playing but not spotify music")
                        KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
                    }
                }
            }
            else {
                print("spotify app is not active")
                KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
            }
        }
    
//    private func isSpotifyAppActive() {
//        if (AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint) {
//            SPTAppRemote.checkIfSpotifyAppIsActive { (isPlaying) in
//                if isPlaying {
//                    print("Spotify is playing")
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "hideLogo"), object: nil)
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.LogInVC.hideLogIn), object: nil)
//                    KeychainWrapper.standard.set(true, forKey: Constants.initiatedSession)
//                }
//                else {
//                    print("audio is playing but not spotify audio")
//                    KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showLogo"), object: nil)
//                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.LogInVC.showLogIn), object: nil)
//                }
//            }
//        }
//        else {
//            print("spotify app is not active")
//            KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showLogo"), object: nil)
//            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.LogInVC.showLogIn), object: nil)
//        }
//    }
    
    private func initializeNumSongsPassed() {
        let numSongsPassed = KeychainWrapper.standard.integer(forKey: Constants.MainVC.numSongsPassed)
        if numSongsPassed == nil {
            KeychainWrapper.standard.set(1, forKey: Constants.MainVC.numSongsPassed)
        }
    }
    
}
