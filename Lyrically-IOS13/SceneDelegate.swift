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

class SceneDelegate: UIResponder, UIWindowSceneDelegate, SPTSessionManagerDelegate {
    
    var tokenManager = TokenManager()
    var currentlyPlaying = CurrentlyPlayingManager()
    
    static private let kAccessTokenKey = "access-token-key"
    
    var window: UIWindow?
    
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
        sessionManager.application(UIApplication.shared, open: url, options: [:])
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("inititated session")
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
        print(#function)
        appRemote.connect()
        NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        artistInfoVC.appRemoteDisconnect()
        appRemote.disconnect()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
        print(#function)
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

extension SceneDelegate: SPTAppRemoteDelegate {
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        artistInfoVC.appRemoteConnected()
        print("connected")
        NotificationCenter.default.post(name: NSNotification.Name("logInSuccessful"), object: nil)
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        artistInfoVC.appRemoteDisconnect()
        print("disconnected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        artistInfoVC.appRemoteDisconnect()
        print("failed")
    }

}



