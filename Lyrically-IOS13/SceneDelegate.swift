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
    
    var window: UIWindow?
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
        print("success", session)
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("fail", error)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("renewed", session)
    }

    let spotifyClientID = Constants.clientID
    let spotifyRedirectURL = Constants.redirectURI
    
    lazy var configuration = SPTConfiguration(clientID: spotifyClientID, redirectURL: URL(string: "Lyrically://callback")!)
    
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
    
    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = Constants.accessToken
        appRemote.delegate = self
        return appRemote
    }()
    
    func login() {
        // check if spotify app is installed
        
        // gets the requuested scopes of the user
        let requestedScopes: SPTScope = [.appRemoteControl, .userReadCurrentlyPlaying, .userReadPlaybackState]
        self.sessionManager.initiateSession(with: requestedScopes, options: .default)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("Opened url")
        // when the user navigates back to the app using the redirect url, this url will have the code used to exchange for the access token
        guard let url = URLContexts.first?.url else {
            return
        }
        
        // parse the url to get the code used to exchange for access token
        var dict = [String:String]()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if let queryItems = components.queryItems {
            for item in queryItems {
                dict[item.name] = item.value!
            }
        }
        
        let _: Bool = KeychainWrapper.standard.set(dict["code"]!, forKey: Constants.code)
        let possibleCode: String? = KeychainWrapper.standard.string(forKey: Constants.code)
        // call method to exchange code for access token
        if let code = possibleCode {
            tokenManager.getAccessToken(spotifyCode: code)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)
        }
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
        
        // at this point, the app is gotten rid of when swiping up and deleting it
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print(#function)
        NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
//        let potentialToken: String? = KeychainWrapper.standard.string(forKey: Constants.accessToken)
//        if let accessToken = potentialToken {
//            print("Got access token: \(accessToken)")
//        }
//        else {
//            print("Did not receive access token")
//        }
        NotificationCenter.default.post(name: NSNotification.Name(Constants.returnToApp), object: nil)
        print(#function)
        
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        // then when window comes back use the information saved in the sceneDidEnterBackground use that information to see whether suer should go into log in screen or straight into the main view controller
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // at this point is when the app goes to background, you can save the information because when app gets destroyed can be unpredictable
        // decide whether user has already logged in, so they won't have to log in again or if the access token is still valid

    }
    
}

extension SceneDelegate: SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    

    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        self.appRemote.playerAPI?.delegate = self
        self.appRemote.playerAPI?.subscribe(toPlayerState: { (result, error) in
          if let error = error {
            debugPrint(error.localizedDescription)
          }
        })
        print("connected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("disconnected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("failed")
    }

    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("player state changed")
    }

}



