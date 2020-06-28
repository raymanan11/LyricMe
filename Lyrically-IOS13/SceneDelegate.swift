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
    private let redirectUri = URL(string:"Lyrically://callback")!
    private let clientIdentifier = "13be0b60a54143b48acd80ba925c0d22"
    
    var window: UIWindow?
    
    lazy var configuration = SPTConfiguration(clientID: self.clientIdentifier, redirectURL: self.redirectUri)
    
    let tokenSwap = "https://tangible-lean-level.glitch.me/api/token"
    let refresh = "https://tangible-lean-level.glitch.me/api/refresh_token"
    
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = URL(string: tokenSwap), let tokenRefreshURL = URL(string: refresh) {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
            self.configuration.playURI = ""
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    
    var accessToken = UserDefaults.standard.string(forKey: kAccessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: SceneDelegate.kAccessTokenKey)
        }
    }
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        print("self.accessToken: \(self.accessToken)")
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
//
//        print("opened url")
//        let parameters = appRemote.authorizationParameters(from: url);
//
//        print(parameters)
//        if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
//            print(access_token)
//            appRemote.connectionParameters.accessToken = access_token
//            self.accessToken = access_token
//        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
//            print(errorDescription)
//        }
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
//        appRemote.connect()
        NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        logInVC.appRemoteDisconnect()
        appRemote.disconnect()
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
        print(#function)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {

    }
    
    var logInVC: LogInViewController {
        get {
            let navController = self.window?.rootViewController as! UINavigationController
            return navController.topViewController as! LogInViewController
        }
    }
    
}

extension SceneDelegate: SPTAppRemoteDelegate {
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        logInVC.appRemoteConnected()
        print("connected")
        NotificationCenter.default.post(name: NSNotification.Name("logInSuccessful"), object: nil)
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        logInVC.appRemoteDisconnect()
        print("disconnected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        logInVC.appRemoteDisconnect()
        print("failed")
    }

}



