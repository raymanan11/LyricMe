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

    var numberOfSongsPassed = 1
    var lastSong: String?
    private var firstAppEntry: Bool = true
    private var firstSignIn: Bool = true
    private var didEnterBackground: Bool = true
    private var connected: Bool = true
    private var openURL: Bool = false
    private var didEnterForeground: Bool = false
    
    var initiatedSession: Bool? = KeychainWrapper.standard.bool(forKey: Constants.initiatedSession)
    let spotifyInstalled: Bool? = KeychainWrapper.standard.bool(forKey: Constants.spotifyInstalled)
    let onMainVC: Bool? = KeychainWrapper.standard.bool(forKey: Constants.onMainVC)
    
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
        DispatchQueue.main.async {
            if let safeSpotifyInstalled = self.spotifyInstalled, safeSpotifyInstalled {
                print("Spotify app authentication")
                self.sessionManager.application(UIApplication.shared, open: url, options: [:])
            }
            else {
                print("Web bitch login")
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
            }
        }
        openURL = true
        firstAppEntry = false
        // after pressing log in button, come back and go straight to main VC
        NotificationCenter.default.post(name: NSNotification.Name(Constants.Segues.successfulLogIn), object: nil)
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // sets initiateSession to either true of false depending on if Spotify app is active, if it is then it'll call appRemote.connect below and go straight to mainVC, if not then it'll show logInVC as well as not hide the buttons because logInVC viewDidLoad depends on initiateSession as well
        didEnterForeground = true
        didEnterBackground = false
        KeychainWrapper.standard.set(findApp(appName: "spotify"), forKey: Constants.spotifyInstalled)
        // first is false so that means app remotes won't conflict when connecting from both sceneWillEnterForeground and didInitiate session, only runs the appRemote.connect from the didInitiate instead of sceneWillEnterForeground
        // only runs after user has authenticated and has spotify app open and exits app and comes back when music is playing
        
        if let safeInitiatedSession = initiatedSession, safeInitiatedSession {
            connected = true
            if let safeSpotifyInstalled = spotifyInstalled, safeSpotifyInstalled {
                print("Connected app remote 2")
                appRemote.connect()
            }
            else {
                // checks if user downloaded Spotify app, if they did, go back to main VC and have them auth through Spotify app
                print("web login process")
                webLogIn()
            }
        }
        else {
            print("something wrong with initiatedSession")
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print(#function)
        print("Spotify Installed: \(findApp(appName: "spotify"))")
        print("Initiated Session: \(initiatedSession)")
        print("App Remote connected: \(appRemote.isConnected)")
        if let safeSpotifyInstalled = spotifyInstalled, !safeSpotifyInstalled && !firstAppEntry {
            startCurrentSongTimer()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.webLogInSetup), name: NSNotification.Name(rawValue: "webLogInSetup"), object: nil)
        // when first entering the app, appRemote.connect() runs from sceneWillEnterForeground() instead of from sceneDidBecomeActive
        // only calls appRemote.connect() whenever user dismisses the pull down menu so that the app can track if user changed the song there or whenever something happens to call this method
        didEnterBackground = false
        if didEnterForeground {
            print("hi")
            didEnterForeground = false
        }
        else {
            print("bye")
            if let safeSpotifyInstalled = spotifyInstalled, safeSpotifyInstalled {
                print("sceneDidbecomeActive spotifyInstalled = \(safeSpotifyInstalled)")
                print("Connected app remote 3")
                appRemote.connect()
            }
        }
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
//        defaults.onMainVC = false
//        KeychainWrapper.standard.set(false, forKey: Constants.onMainVC)
        didEnterBackground = true
        print(#function)
        if let safeSpotifyInstalled = spotifyInstalled, safeSpotifyInstalled {
            appRemote.disconnect()
        }
        else {
            self.stopCurrentSongTimer()
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "webLogInSetup"), object: nil)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print(#function)
        didEnterBackground = true
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        firstSignIn = true
        print(#function)
    }
    
    fileprivate func webLogIn() {
        DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
            if self.findApp(appName: "spotify") {
                print("1")
                self.stopCurrentSongTimer()
                self.updateLogInUI()
                NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.returnToLogInVC), object: nil)
            }
            // else go straight to main VC and get lyrics
            else if self.firstAppEntry {
                print("2")
                print("going to main vc bc web log in and getting song info")
                self.firstAppEntry = false
                NotificationCenter.default.post(name: NSNotification.Name(Constants.Segues.successfulLogIn), object: nil)
                print("bats3")
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
        print("Starting timer")
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
            DispatchQueue.main.async {
                print("calling get currently playing song")
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
        print("Authentication through web log in")
        let accessToken: String? = KeychainWrapper.standard.string(forKey: Constants.Tokens.accessToken)
        let refreshToken: String? = KeychainWrapper.standard.string(forKey: Constants.Tokens.refreshToken)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.updateStatus), object: nil)
        }
        initiatedSession = KeychainWrapper.standard.set(true, forKey: Constants.initiatedSession)
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        print("bats")
        startCurrentSongTimer()
        
    }
    
    func findApp(appName:String) -> Bool {

        let appName = "spotify"
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
        // main VC default setup before updating main VC for lyrics and artist info
//        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.updateStatus), object: nil)
//        }
        initiatedSession = KeychainWrapper.standard.set(true, forKey: Constants.initiatedSession)
        appRemote.connectionParameters.accessToken = session.accessToken
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        // connect the app remote
        print("Connected app remote 1")
        appRemote.connect()
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        // if it fails, go back to log in VC where user can log in again
        DispatchQueue.main.asyncAfter(deadline: 2.second.fromNow) {
            self.updateLogInUI()
            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.returnToLogInVC), object: nil)
        }
        print("fail", error)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("renewed", session)
    }
    
}

// MARK: - SPTAppRemoteDelegate

extension SceneDelegate: SPTAppRemoteDelegate {

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        subscribeToCapabilityChanges()
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
          if let error = error {
            debugPrint(error.localizedDescription)
          }
        })
        // only goes to mainVC if first entering app so that it won't keep showing transition screen every time user switches back and forth between spotify screen
        // somehow check if lyrics have not been received along with first app entry
        // goes to mainVC only if spotify music is playing because
        print(self.appRemote.isConnected)
        if firstAppEntry, let safeOnMainVC = onMainVC, !safeOnMainVC {
            print("Going to mainVC bitch")
            NotificationCenter.default.post(name: NSNotification.Name(Constants.Segues.successfulLogIn), object: nil)
        }
        else {
            print(firstAppEntry)
            if let safeOnMainVC = onMainVC {
                print(safeOnMainVC)
            }
            print("already on main VC")
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        connected = false
        print("appRemote didDisconnectWithError")
//        initiatedSession = KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
        if !self.connected && !self.didEnterBackground {
            print("appRemote didDisconnect inside if statement")
            initiatedSession = KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
            lastSong = nil

            updateLogInUI()
            // return to log in VC if it fails
            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.returnToLogInVC), object: nil)
        }
        print("disconnected")
    }
    

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        updateLogInUI()
        firstSignIn = true
        print("failed", error)
        if !firstAppEntry {
            // reset the last song to nil so it won't remember the past song so it will update lyrics again
            lastSong = nil
            // return to log in VC if it fauls
            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.returnToLogInVC), object: nil)
        }
    }
    
    func updateLogInUI() {
        NotificationCenter.default.post(name: NSNotification.Name(Constants.ArtistVC.dismissArtistVC), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("showLogo"), object: nil)
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
        print(initiatedSession)
        if let safeInitiatedSession = initiatedSession, safeInitiatedSession {
            fetchUserCapabilities()
            if playerState.track.name != lastSong {
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
    }
    
    private func showAds() {
        print(KeychainWrapper.standard.integer(forKey: Constants.MainVC.numSongsPassed))
        if let numSongsPasssed = KeychainWrapper.standard.integer(forKey: Constants.MainVC.numSongsPassed), numSongsPasssed == 7 {
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




