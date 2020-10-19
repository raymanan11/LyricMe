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
import AVFoundation

protocol HasLyrics {
    func getInfo()
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    var currentlyPlaying = CurrentlyPlayingManager()
    var spotifyArtistImageManager = SpotifyArtistImageManager()
    var idParser = IDParser()
    var tokenManager = TokenManager()
    var timer: Timer?
    
    var firstCurrentSong: CurrentlyPlayingInfo?

    private let playURI = "spotify:track:1mea3bSkSGXuIRvnydlB5b"
    var numberOfSongsPassed = 1
    var lastSong: String?
    var onMainVCSong: String?
    private var firstAppEntry: Bool = true
    private var firstSignIn: Bool = true
    private var openURL: Bool = false

    
    var initiatedSession: Bool? = KeychainWrapper.standard.bool(forKey: Constants.initiatedSession)
    var spotifyInstalled: Bool? = KeychainWrapper.standard.bool(forKey: Constants.spotifyInstalled)
    let onMainVC: Bool? = KeychainWrapper.standard.bool(forKey: Constants.onMainVC)
    
    lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: Constants.clientID, redirectURL: Constants.redirectURI)
        configuration.playURI = ""
        return configuration
    }()
    
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: Constants.tokenSwapURL), let tokenRefreshURL = URL(string: Constants.refreshURL) {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
            self.configuration.playURI = ""
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    
    var mainVC: MainViewController {
        get {
            let mainVC = self.window?.rootViewController?.children[1] as! MainViewController
            return mainVC
        }
    }
    
    var accessToken = KeychainWrapper.standard.string(forKey: Constants.Tokens.accessToken) {
        didSet {
            let _: Bool = KeychainWrapper.standard.set(accessToken!, forKey: Constants.Tokens.accessToken)
        }
    }
    
    var refreshToken = KeychainWrapper.standard.string(forKey: Constants.Tokens.refreshToken) {
        didSet {
            let _: Bool = KeychainWrapper.standard.set(refreshToken!, forKey: Constants.Tokens.refreshToken)
        }
    }
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()
    
    // MARK: - SceneDelegate Methods
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        NotificationCenter.default.post(name: NSNotification.Name(Constants.LogInVC.hideLogIn), object: nil)
        guard let url = URLContexts.first?.url else {
            return
        }
        let parameters = appRemote.authorizationParameters(from: url);

        if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = access_token
            self.accessToken = access_token
        }
        else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            print(error_description)
        }
        
        if let safeSpotifyInstalled = self.spotifyInstalled, safeSpotifyInstalled {
            print("Spotify app authentication")
            self.sessionManager.application(UIApplication.shared, open: url, options: [:])
        }
        else {
            print("Web authentication")
            // dismiss the log in page
            NotificationCenter.default.post(name: NSNotification.Name("dismissWebLogin"), object: nil)
            // switch code for accessToken / refresh token into Keychain by using tokenManager
            var dict = [String:String]()
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            if let queryItems = components.queryItems {
                for item in queryItems {
                    dict[item.name] = item.value!
                }
            }

            Constants.code = dict["code"]

            self.tokenManager.getAccessToken(spotifyCode: Constants.code!)
            
            NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
        }
        
//        DispatchQueue.main.asyncAfter(deadline: 0.second.fromNow) {
//            if let safeSpotifyInstalled = self.spotifyInstalled, safeSpotifyInstalled {
//                print("Spotify app authentication")
//                self.sessionManager.application(UIApplication.shared, open: url, options: [:])
//            }
//            else {
//                print("Web authentication")
//                // dismiss the log in page
//                NotificationCenter.default.post(name: NSNotification.Name("dismissWebLogin"), object: nil)
//                // switch code for accessToken / refresh token into Keychain by using tokenManager
//                var dict = [String:String]()
//                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
//                if let queryItems = components.queryItems {
//                    for item in queryItems {
//                        dict[item.name] = item.value!
//                    }
//                }
//
//                Constants.code = dict["code"]
//
//                self.tokenManager.getAccessToken(spotifyCode: Constants.code!)
//
//                NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
//            }
//        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
        KeychainWrapper.standard.set(findApp(appName: "spotify"), forKey: Constants.spotifyInstalled)
        
        spotifyInstalled = KeychainWrapper.standard.bool(forKey: Constants.spotifyInstalled)
        
        if let safeSpotifyInstalled = spotifyInstalled, safeSpotifyInstalled {
            print("spotify is installed!")
        }
        else {
            print("spotify is not installed!")
        }
        
        print(#function)
        if let safeSpotifyInstalled = spotifyInstalled, safeSpotifyInstalled {
            appRemote.connect()
        }
        else {
            // if spotifyInstalled is false and you try to connect it, it will go to didFailConnectionWithError meaning it will go back to login page but then everytime it will do this and everytime it will go to LogInVC which we don't want
            appRemote.connect()
            self.startCurrentSongTimer()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print(#function)
        if let safeSpotifyInstalled = spotifyInstalled, safeSpotifyInstalled {
            onMainVCSong = lastSong
            appRemote.disconnect()
        }
        else {
            self.stopCurrentSongTimer()
        }
        lastSong = nil
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "webLogInSetup"), object: nil)
    }
    
    fileprivate func webLogIn() {
        DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
            if self.findApp(appName: "spotify") {
                self.stopCurrentSongTimer()
                self.updateLogInUI()
                NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.returnToLogInVC), object: nil)
            }
            // else go straight to main VC and get lyrics
            else if self.firstAppEntry {
                self.firstAppEntry = false
                NotificationCenter.default.post(name: NSNotification.Name(Constants.Segues.successfulLogIn), object: nil)
                self.startCurrentSongTimer()
            }
        }
    }
    
    // MARK: - Methods used by SceneDelegate methods
    func login() {
        // gets the requuested scopes of the user
        let requestedScopes: SPTScope = [.appRemoteControl, .userReadCurrentlyPlaying, .userReadPlaybackState]
        self.sessionManager.initiateSession(with: requestedScopes, options: .default)
    }
    
    private func startCurrentSongTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
            DispatchQueue.main.async {
                print("calling get currently playing song from timer")
                self.getCurrentlyPlayingSong()
            }
        }
    }
    
    private func stopCurrentSongTimer() {
        if let safeTimer = self.timer {
            safeTimer.invalidate()
        }
    }
    
    @objc func webLogInSetup() {
        let accessToken: String? = KeychainWrapper.standard.string(forKey: Constants.Tokens.accessToken)
        let refreshToken: String? = KeychainWrapper.standard.string(forKey: Constants.Tokens.refreshToken)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.updateStatus), object: nil)
        }
        initiatedSession = KeychainWrapper.standard.set(true, forKey: Constants.initiatedSession)
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        startCurrentSongTimer()
        
    }
    
    func checkIfSpotifyIsInstalled() {
        if appRemote.isConnected == false {
            if appRemote.authorizeAndPlayURI(playURI) == false {
                spotifyInstalled = KeychainWrapper.standard.set(false, forKey: Constants.spotifyInstalled)
                print("spotify is not installed!")
            }
        }
        else {
            spotifyInstalled = KeychainWrapper.standard.set(true, forKey: Constants.spotifyInstalled)
            print("spotify is installed!")
        }
    }
    
    func findApp(appName:String) -> Bool {

        let appScheme = "\(appName)://app"
        let appUrl = URL(string: appScheme)

        if UIApplication.shared.canOpenURL(appUrl! as URL) {
            return true
        }
        return false
    }

}

// MARK: - SPTSessionManagerDelegate

extension SceneDelegate: SPTSessionManagerDelegate {
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("inititated session")
        initiatedSession = KeychainWrapper.standard.set(true, forKey: Constants.initiatedSession)
        appRemote.connectionParameters.accessToken = session.accessToken
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        // connect the app remote
        print("appRemote.connect() 3")
        appRemote.connect()
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        // if it fails, go back to log in VC where user can log in again
        DispatchQueue.main.asyncAfter(deadline: 2.second.fromNow) {
            self.updateLogInUI()
            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.returnToLogInVC), object: nil)
        }
        print("fail sessionManager", error)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("renewed", session)
    }
    
}

// MARK: - SPTAppRemoteDelegate

extension SceneDelegate: SPTAppRemoteDelegate {

    private func moveToMainVC() {
        if let viewControllers = window?.rootViewController?.children {
            for viewController in viewControllers {  
                if viewController is MainViewController {
                    lastSong = onMainVCSong
                    return
                }
            }
            print("Moving to MainVC")
            NotificationCenter.default.post(name: NSNotification.Name(Constants.Segues.successfulLogIn), object: nil)
        }
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("appRemoteDidEstablishConnection")
        self.appRemote = appRemote
        subscribeToCapabilityChanges()
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
          if let error = error {
            debugPrint(error.localizedDescription)
          }
        })
        moveToMainVC()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("didDisconnectWithError")
        if let safeError = error {
            print(safeError)
        }
        updateLogInUI()
    }
    

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("didFailConnectionAttemptWithError")
        if let safeError = error {
            print(safeError)
        }
        // the logInButton is showing but because I hid the button in viewWillAppear, the logInButton is hidden
        
        NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.returnToLogInVC), object: nil)
        updateLogInUI()
    }
    
    func updateLogInUI() {
        NotificationCenter.default.post(name: NSNotification.Name(Constants.ArtistVC.dismissArtistVC), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(Constants.LogInVC.showLogIn), object: nil)
   }
    
    private func subscribeToCapabilityChanges() {
        appRemote.userAPI?.delegate = self
        appRemote.userAPI?.subscribe(toCapabilityChanges: { (success, error) in
            guard error == nil else { return }
        })
    }
    
    private func fetchUserCapabilities() {
        appRemote.userAPI?.fetchCapabilities(callback: { (capabilities, error) in
            guard error == nil else { return }

            let capabilities = capabilities as! SPTAppRemoteUserCapabilities
            self.updateViewWithCapabilities(capabilities)
        })
    }
    
    private func updateViewWithCapabilities(_ capabilities: SPTAppRemoteUserCapabilities) {
        MainViewController.playOnDemand = capabilities.canPlayOnDemand
    }
    
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SceneDelegate: SPTAppRemotePlayerStateDelegate {
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("In playerStateDidChange")
        fetchUserCapabilities()
        print("playerStateDidChange playerState.track.name: \(playerState.track.name)")
        print("playerStateDidChange               lastSong: \(lastSong)")
        if playerState.track.name != lastSong {
            print("playerState song does not equal last song!")
            // increase number of songs passed to user defaults so ads will be able to show up
            if lastSong != nil {
                if let numSongsPassed = KeychainWrapper.standard.integer(forKey: Constants.MainVC.numSongsPassed) {
                    KeychainWrapper.standard.set(numSongsPassed + 1, forKey: Constants.MainVC.numSongsPassed)
                }
            }
            updateLyrics(playerState)
            // show ads every 7 songs
            showAds()
        }
        lastSong = playerState.track.name
        mainVC.updateRestrictions(playerState.playbackRestrictions)
        updateRestrictionOnSkipButtons()
    }
    
    private func showAds() {
        if let numSongsPassed = KeychainWrapper.standard.integer(forKey: Constants.MainVC.numSongsPassed), numSongsPassed == 6 {
            print("numSongsPassed: \(numSongsPassed)")
            KeychainWrapper.standard.set(0, forKey: Constants.MainVC.numSongsPassed)
            DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
                NotificationCenter.default.post(name: NSNotification.Name("showAd"), object: nil)
            }
        }
    }
    
    private func updateLyrics(_ playerState: SPTAppRemotePlayerState) {
        // if first open URL and first sign in, update lyrics and artist info the alternate way because there is a bug that sometimes has incorrect information if using spotify api
        if openURL && firstSignIn {
            print("alt")
            DispatchQueue.main.async {
                self.alternateGetCurrentlyPlayingSong(playerState)
            }
            openURL = false
            firstSignIn = false
        }
        // if not, use spotify api to request user's currently playing info to update lyrics and artist info
        else {
            print("main")
            firstAppEntry = false
            DispatchQueue.main.async {
                self.getCurrentlyPlayingSong()
            }
        }
    }
    
    func alternateGetCurrentlyPlayingSong(_ playerState: SPTAppRemotePlayerState) {
        let artistName = playerState.track.artist.name
        let fullSongName = playerState.track.name
        let currentSongURI = playerState.track.uri
        let apiSongName = currentlyPlaying.checkSongName(fullSongName)
        let artistID = idParser.parseURI(uri: playerState.track.artist.uri)
        firstCurrentSong = CurrentlyPlayingInfo(artistName: artistName, fullSongName: fullSongName, apiSongName: apiSongName, allArtists: artistName, albumURL: "", artistID: artistID, currentSongURI: currentSongURI)
        if let safeFirstSong = firstCurrentSong {
            self.mainVC.getFirstSong(info: safeFirstSong)
        }
    }
    
    func getCurrentlyPlayingSong() {
        DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
            NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
        }
    }
    
    func updateRestrictionOnSkipButtons() {
        DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.updateRestrictions), object: nil)
        }
    }
}

// MARK: - SPTAppRemoteUserAPIDelegate

extension SceneDelegate: SPTAppRemoteUserAPIDelegate {
    func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) { }
}



