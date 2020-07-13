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
    
    var currentlyPlaying = CurrentlyPlayingManager()
    var spotifyArtistImageManager = SpotifyArtistImageManager()

    var lastSong: String?
    var openURL: Bool = false
    private var firstAppEntry: Bool = true
    private var didEnterForeground: Bool = false
    private var didEnterBackground: Bool = true
    private var connected: Bool = true
    
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
        print("Opened url!")
        openURL = true
        NotificationCenter.default.post(name: NSNotification.Name("openSpotify"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("logInSuccessful"), object: nil)
        print("Moved to Main VC from openURL")
        firstAppEntry = false
        sessionManager.application(UIApplication.shared, open: url, options: [:])
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("inititated session")
        let defaults = UserDefaults.standard
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
        print(#function)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print(#function)
        // when first signing in, it will enter foreground (true) and appRemote.connect will connect which is why I did this so it won't call appRemote.connect() another time to stop any conflicts
        // but then will set didEnterForeground to false in order to call appRemote.connect() whenever user dismisses the pull down menu so that the app can track if user changed the song there
        didEnterBackground = false
        if didEnterForeground {
            print("didEnterForeground and now changed to false")
            didEnterForeground = false
        }
        else {
            print("Pull down menu engaged and app remote connecting")
            appRemote.connect()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print(#function)
        didEnterBackground = true
        appRemote.disconnect()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print(#function)
        print("returned to app")
        didEnterForeground = true
        didEnterBackground = false
        let defaults = UserDefaults.standard
        // first is false so that means app remotes won't conflict when connecting from both sceneWillEnterForeground and didInitiate session, only runs the appRemote.connect from the didInitiate instead of sceneDidBecomeActive
        // only runs after user has authenticated and has spotify app open
        if defaults.initiatedSession {
            connected = true
            print("Connected: \(connected)")
            print("initiated session and getting app remote to connect")
            appRemote.connect()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        didEnterBackground = true
        print(#function)
    }
    
    var mainVC: MainViewController {
        get {
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
        print("First time logging in: \(firstAppEntry)")
        // only goes to mainVC if first entering app so that it won't keep showing transition screen every time user switches back and forth between spotify screen
        if firstAppEntry {
            print("Moved to Main VC from appRemoteDidEstablishConnection")
            NotificationCenter.default.post(name: NSNotification.Name("logInSuccessful"), object: nil)
            firstAppEntry = false
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        connected = false
        if !self.connected && !self.didEnterBackground {
            print("Spotify app has been on pause for too long and can't connect again, going back to the log in screen!")
            let defaults = UserDefaults.standard
            defaults.initiatedSession = false
            
            lastSong = nil

            NotificationCenter.default.post(name: NSNotification.Name("closedSpotify"), object: nil)
            let rootViewController = self.window!.rootViewController as! UINavigationController
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let logInVC = mainStoryboard.instantiateViewController(withIdentifier: "logIn") as! LogInViewController
            rootViewController.pushViewController(logInVC, animated: true)
        }
        print("Connected: \(self.connected)")
        print("disconnected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        
        let defaults = UserDefaults.standard
        defaults.initiatedSession = false
        
        NotificationCenter.default.post(name: NSNotification.Name("closedSpotify"), object: nil)
        print("failed")
        if !firstAppEntry {
            print("Not the first entry")
            lastSong = nil
            let rootViewController = self.window!.rootViewController as! UINavigationController
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let logInVC = mainStoryboard.instantiateViewController(withIdentifier: "logIn") as! LogInViewController
            rootViewController.pushViewController(logInVC, animated: false)
        }
    }

}

extension SceneDelegate: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        if playerState.track.name != lastSong {
            if openURL {
                print("First time coming back after opening url using playerStateDidChange info for currently playing info")
                let artistName = playerState.track.artist.name
                let fullSongName = playerState.track.name
                let apiSongName = currentlyPlaying.checkSongName(fullSongName)
                let artistID = parseURI(artistURI: playerState.track.artist.uri)
                let firstCurrentSong = CurrentlyPlayingInfo(artistName: artistName, fullSongName: fullSongName, apiSongName: apiSongName, allArtists: artistName, albumURL: "", artistID: artistID)
                mainVC.getFirstSong(firstSong: firstCurrentSong)
                openURL = false
                // be aware of state of openURL like when force closing app for example
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
                    NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
                }
            }
        }
        lastSong = playerState.track.name
    }

    func parseURI(artistURI: String) -> String {
        let parts = artistURI.components(separatedBy: ":")
        // find  more elegant way to get artistID
        return parts[2]
    }
}



