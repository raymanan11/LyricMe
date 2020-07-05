//
//  SceneDelegate.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 5/8/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import UIKit
import Alamofire
import SwiftKeychainWrapper

protocol HasLyrics {
    func getInfo()
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SPTSessionManagerDelegate {
    
    var tokenManager = TokenManager()
    var currentlyPlaying = CurrentlyPlayingManager()
    
    private var firstAppEntry: Bool = true
    static private let kAccessTokenKey = "access-token-key"
    
    var delegate: HasLyrics?
    
    var window: UIWindow?
    var lastSong: String?
    
    lazy var configuration = SPTConfiguration(clientID: Constants.clientID, redirectURL: Constants.redirectURI)
    
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: Constants.tokenSwapURL), let tokenRefreshURL = URL(string: Constants.refreshURL) {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
            self.configuration.playURI = ""
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    
    // whenever a new value is assigned to this variable, didSet is called so it will update the userDefaults for the access token, otherwise you just get the value of the variable
    var accessToken = UserDefaults.standard.string(forKey: kAccessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: SceneDelegate.kAccessTokenKey)
        }
    }
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()
    
    func login() {
        // check if spotify app is installed
        
        // gets the requuested scopes of the user
        let requestedScopes: SPTScope = [.appRemoteControl, .userReadCurrentlyPlaying, .userReadPlaybackState]
        self.sessionManager.initiateSession(with: requestedScopes, options: .clientOnly)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        print("Opened url!")
        NotificationCenter.default.post(name: NSNotification.Name("openSpotify"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("logInSuccessful"), object: nil)
        firstAppEntry = false
        sessionManager.application(UIApplication.shared, open: url, options: [:])
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        // boolean for login
        print("inititated session")
        print("Scene delegate access token: \(session.accessToken)")
        
        let defaults = UserDefaults.standard
        defaults.initiatedSession = true
//        initiatedSession = true
        appRemote.connectionParameters.accessToken = session.accessToken
        self.accessToken = session.accessToken
        appRemote.connect()
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("fail", error)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("renewed", session)
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {

    }

    func sceneDidBecomeActive(_ scene: UIScene) {
//        print(#function)
//        print("returned to app")
//        let defaults = UserDefaults.standard
//        // first is false so that means app remotes won't conflict when connecting from both sceneDidBecomeActive and didInitiate session, only runs the appRemote.connect from the didInitiate instead of sceneDidBecomeActive
//        // only runs after user has authenticated and has spotify app open
//        if defaults.initiatedSession {
//            print("initiated session and getting app remote to connect")
//            appRemote.connect()
//        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
//        artistInfoVC.appRemoteDisconnect()
        appRemote.disconnect()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print(#function)
        print("returned to app")
        let defaults = UserDefaults.standard
        // first is false so that means app remotes won't conflict when connecting from both sceneDidBecomeActive and didInitiate session, only runs the appRemote.connect from the didInitiate instead of sceneDidBecomeActive
        // only runs after user has authenticated and has spotify app open
        if defaults.initiatedSession {
            print("initiated session and getting app remote to connect")
            appRemote.connect()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {

    }
    
    var artistInfoVC: ArtistInfoViewController {
        get {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let artistVC = mainStoryboard.instantiateViewController(withIdentifier: "artistInfo") as! ArtistInfoViewController
            return artistVC
        }
    }
    
}

extension UserDefaults {
    var initiatedSession: Bool {
        get {
            if let initiateSession = UserDefaults.standard.object(forKey: "initiatedSession") as? Bool {
                return initiateSession
            }
            else {
                print("in here")
                return false
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "initiatedSession")
        }
    }
}

extension SceneDelegate: SPTAppRemoteDelegate {
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
          if let error = error {
            debugPrint(error.localizedDescription)
          }
        })
//        artistInfoVC.appRemoteConnected()
        print("connected")
        print("First time logging in: \(firstAppEntry)")
        // only goes to mainVC if first entering app so that it won't keep showing transition screen every time user switches back and forth between spotify screen
        if firstAppEntry {
            NotificationCenter.default.post(name: NSNotification.Name("logInSuccessful"), object: nil)
            firstAppEntry = false
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
//        artistInfoVC.appRemoteDisconnect()
        print("disconnected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
//        artistInfoVC.appRemoteDisconnect()
        // post notification that spotify app has been closed and show the log in button again
        NotificationCenter.default.post(name: NSNotification.Name("spotifyClosed"), object: nil)
        print("failed")
    }

}

extension SceneDelegate: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        if playerState.track.name != lastSong {
            print("in here")
            DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
                NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
            }
            lastSong = playerState.track.name
        }
    }
}



