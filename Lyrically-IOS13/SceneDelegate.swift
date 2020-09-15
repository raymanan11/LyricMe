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
        defaults.initiatedSession = true
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        
        print("bats")
        startCurrentSongTimer()
        
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        NotificationCenter.default.post(name: NSNotification.Name(Constants.LogInVC.hideLogIn), object: nil)
        guard let url = URLContexts.first?.url else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
            if self.defaults.spotifyInstalled {
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
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("inititated session")
        // main VC default setup before updating main VC for lyrics and artist info
//        DispatchQueue.main.async {
//            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.updateStatus), object: nil)
//        }
        defaults.initiatedSession = true
        appRemote.connectionParameters.accessToken = session.accessToken
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        // connect the app remote
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
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        firstSignIn = true
        print(#function)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print(#function)
        defaults.spotifyInstalled = findApp(appName: "spotify")
        print(defaults.spotifyInstalled)
        if !defaults.spotifyInstalled && !firstAppEntry {
            startCurrentSongTimer()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.webLogInSetup), name: NSNotification.Name(rawValue: "webLogInSetup"), object: nil)
        // when first signing in, it will enter foreground (true) and appRemote.connect will connect which is why I did this so it won't call appRemote.connect() another time to stop any conflicts
        // but then will set didEnterForeground to false in order to call appRemote.connect() whenever user dismisses the pull down menu so that the app can track if user changed the song there
        didEnterBackground = false
        if didEnterForeground {
            print("hi")
            didEnterForeground = false
        }
        else {
            print("bye")
            if defaults.spotifyInstalled {
                print("sceneDidbecomeActive spotifyInstalled = \(defaults.spotifyInstalled)")
                appRemote.connect()
            }
        }
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        defaults.onMainVC = false
        didEnterBackground = true
        print(#function)
        if defaults.spotifyInstalled {
            appRemote.disconnect()
        }
        else {
            self.stopCurrentSongTimer()
        }
        
        NotificationCenter.default.removeObserver(self,  name: NSNotification.Name(rawValue: "webLogInSetup"), object: nil)
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        didEnterForeground = true
        didEnterBackground = false
        // first is false so that means app remotes won't conflict when connecting from both sceneWillEnterForeground and didInitiate session, only runs the appRemote.connect from the didInitiate instead of sceneDidBecomeActive
        // only runs after user has authenticated and has spotify app open
        if defaults.initiatedSession {
            connected = true
            if defaults.spotifyInstalled {
                appRemote.connect()
            }
            else {
                // checks if user downloaded Spotify app, if they did, go back to main VC and have them auth through Spotify app
                print("web login process")
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
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print(#function)
        didEnterBackground = true
    }
    
    var mainVC: MainViewController {
        get {
            let mainVC = self.window?.rootViewController?.children[1] as! MainViewController
            return mainVC
        }
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
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
    
    var spotifyInstalled: Bool {
        get {
            if let initiateSession = UserDefaults.standard.object(forKey: "spotifyInstalled") as? Bool {
                return initiateSession
            }
            else {
                return false
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "spotifyInstalled")
        }
    }
    
    var onMainVC: Bool {
        get {
            if let onMainVC = UserDefaults.standard.object(forKey: "onMainVC") as? Bool {
                return onMainVC
            }
            else {
                return false
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "onMainVC")
        }
    }
    
}

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
//        print("onMainVC: \(defaults.onMainVC)")
        if firstAppEntry && !self.defaults.onMainVC {
            print("Going to mainVC bitch")
            NotificationCenter.default.post(name: NSNotification.Name(Constants.Segues.successfulLogIn), object: nil)
        }
        else {
            print("unable to go into main VC bitch")
        }
//        if firstAppEntry {
//            print("Going to mainVC bitch")
//            NotificationCenter.default.post(name: NSNotification.Name(Constants.Segues.successfulLogIn), object: nil)
//        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        connected = false
        if !self.connected && !self.didEnterBackground {
            let defaults = UserDefaults.standard
            defaults.initiatedSession = false
            
            lastSong = nil

            updateLogInUI()
//             return to log in VC if it fails
            NotificationCenter.default.post(name: NSNotification.Name(Constants.MainVC.returnToLogInVC), object: nil)
        }
        print("disconnected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        updateLogInUI()
        defaults.initiatedSession = false
        firstSignIn = true
        print("failed", error)
        if !firstAppEntry {
            // reset the last song to nil so it won't remember the past song so it will update lyrics again
            lastSong = nil
//             return to log in VC if it fauls
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

extension SceneDelegate: SPTAppRemotePlayerStateDelegate {
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        if defaults.initiatedSession {
            fetchUserCapabilities()
            if playerState.track.name != lastSong {
                // increase number of songs passed to user defaults so ads will be able to show up
                if lastSong != nil {
                    defaults.set(defaults.integer(forKey: Constants.MainVC.numSongsPassed) + 1, forKey: Constants.MainVC.numSongsPassed)
                }
                print(defaults.integer(forKey: Constants.MainVC.numSongsPassed))
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
                // show ads every 7 songs
                showAds()
            }
            lastSong = playerState.track.name
            mainVC.updateRestrictions(playerState.playbackRestrictions)
            updateRestrictionOnSkipButtons()
        }
    }
    
    private func showAds() {
        if defaults.integer(forKey: Constants.MainVC.numSongsPassed) == 7 {
            defaults.set(0, forKey: Constants.MainVC.numSongsPassed)
            DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
                NotificationCenter.default.post(name: NSNotification.Name("showAd"), object: nil)
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

extension SceneDelegate: SPTAppRemoteUserAPIDelegate {
    func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) { }
}




