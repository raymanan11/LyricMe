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
    
    var window: UIWindow?
    
    let defaults = UserDefaults.standard
    var currentlyPlaying = CurrentlyPlayingManager()
    var spotifyArtistImageManager = SpotifyArtistImageManager()
    
    var firstCurrentSong: CurrentlyPlayingInfo?

    var lastSong: String?
    private var firstAppEntry: Bool = true
    private var firstSignIn: Bool = true
    private var didEnterBackground: Bool = true
    private var connected: Bool = true
    private var openURL: Bool = false
    private var didEnterForeground: Bool = false
    
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
    
    var accessToken = KeychainWrapper.standard.string(forKey: Constants.accessToken) {
        didSet {
            let _: Bool = KeychainWrapper.standard.set(accessToken!, forKey: Constants.accessToken)
        }
    }
    
    var refreshToken = KeychainWrapper.standard.string(forKey: Constants.refreshToken) {
        didSet {
            let _: Bool = KeychainWrapper.standard.set(refreshToken!, forKey: Constants.refreshToken)
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
        openURL = true
        NotificationCenter.default.post(name: NSNotification.Name("openSpotify"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("logInSuccessful"), object: nil)
        firstAppEntry = false
        sessionManager.application(UIApplication.shared, open: url, options: [:])

    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("inititated session")
        NotificationCenter.default.post(name: NSNotification.Name("updateStatus"), object: nil)
        defaults.initiatedSession = true
        appRemote.connectionParameters.accessToken = session.accessToken
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
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
        firstSignIn = true
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // when first signing in, it will enter foreground (true) and appRemote.connect will connect which is why I did this so it won't call appRemote.connect() another time to stop any conflicts
        // but then will set didEnterForeground to false in order to call appRemote.connect() whenever user dismisses the pull down menu so that the app can track if user changed the song there
        didEnterBackground = false
        if didEnterForeground {
            didEnterForeground = false
        }
        else {
            appRemote.connect()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        didEnterBackground = true
        appRemote.disconnect()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        didEnterForeground = true
        didEnterBackground = false
        // first is false so that means app remotes won't conflict when connecting from both sceneWillEnterForeground and didInitiate session, only runs the appRemote.connect from the didInitiate instead of sceneDidBecomeActive
        // only runs after user has authenticated and has spotify app open
        if defaults.initiatedSession {
            connected = true
            appRemote.connect()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        didEnterBackground = true
    }
    
    var mainVC: MainViewController {
        get {
            print("problem")
            let mainVC = self.window?.rootViewController?.children[1] as! MainViewController
            return mainVC
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
        // only goes to mainVC if first entering app so that it won't keep showing transition screen every time user switches back and forth between spotify screen
        if firstAppEntry {
            NotificationCenter.default.post(name: NSNotification.Name("logInSuccessful"), object: nil)
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        connected = false
        if !self.connected && !self.didEnterBackground {
            let defaults = UserDefaults.standard
            defaults.initiatedSession = false
            
            lastSong = nil

            NotificationCenter.default.post(name: NSNotification.Name("playButtonPressed"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("closedSpotify"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("returnToLogIn"), object: nil)
        }
        print("disconnected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        NotificationCenter.default.post(name: NSNotification.Name("playButtonPressed"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("closedSpotify"), object: nil)
        defaults.initiatedSession = false
        firstSignIn = true
        print("failed")
        if !firstAppEntry {
            lastSong = nil
            NotificationCenter.default.post(name: NSNotification.Name("returnToLogIn"), object: nil)
        }
    }
    
    private func returnToLogIn() {
        let rootViewController = self.window!.rootViewController as! UINavigationController
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let logInVC = mainStoryboard.instantiateViewController(withIdentifier: "logIn") as! LogInViewController
        rootViewController.pushViewController(logInVC, animated: true)
    }

}

extension SceneDelegate: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        if playerState.track.name != lastSong {
            if openURL && firstSignIn {
                let artistName = playerState.track.artist.name
                let fullSongName = playerState.track.name
                let apiSongName = currentlyPlaying.checkSongName(fullSongName)
                let artistID = parseURI(artistURI: playerState.track.artist.uri)
                firstCurrentSong = CurrentlyPlayingInfo(artistName: artistName, fullSongName: fullSongName, apiSongName: apiSongName, allArtists: artistName, albumURL: "", artistID: artistID)
                if let safeFirstSong = firstCurrentSong {
                    self.mainVC.getFirstSong(info: safeFirstSong)
                }
                firstSignIn = false
                openURL = false
            }
            else {
                firstAppEntry = false
                DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
                    NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
                }
            }
        }
        lastSong = playerState.track.name
    }

    func parseURI(artistURI: String) -> String? {
        if artistURI == "" {
            return nil
        }
        let parts = artistURI.components(separatedBy: ":")
        return parts[2]
    }
}



