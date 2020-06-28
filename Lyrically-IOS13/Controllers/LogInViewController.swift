
import UIKit
import SafariServices
import AVFoundation
import Alamofire
import SwiftKeychainWrapper

class LogInViewController: UIViewController {
    @IBOutlet weak var logIn: UIButton!
    
    var sceneDelegate = SceneDelegate()
    
    private var playerState: SPTAppRemotePlayerState?
    private var subscribedToPlayerState: Bool = false
    private var subscribedToCapabilities: Bool = false
    
    var defaultCallback: SPTAppRemoteCallback {
        get {
            return {[weak self] _, error in
                if let error = error {
                    print(error)
                }
            }
        }
    }
    
    var appRemote: SPTAppRemote? {
        get {
            return (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.appRemote
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        let accessToken: String? = KeychainWrapper.standard.string(forKey: Constants.accessToken)
//        if accessToken != nil {
//            // go straight to main VC to check if access token is valid or not
//            // if not valid, call refresh token
//            // if is, then use it to get currently playing info
//            print(#function)
//            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            let mainViewController = storyBoard.instantiateViewController(withIdentifier: "main") as! MainViewController
//            self.navigationController?.pushViewController(mainViewController, animated: false)
//        }
//    }
    @IBAction func playSong(_ sender: UIButton) {
        appRemote?.playerAPI?.play("spotify:track:20I6sIOMTCkB6w7ryavxtO", callback: defaultCallback)
    }
    
    @IBAction func logIn(_ sender: Any) {
        sceneDelegate.login()
    }
    
    @objc func moveToNextVC() {
        performSegue(withIdentifier: Constants.goToMainVC, sender: self)
    }
    
    func appRemoteConnected() {
        print("appRemoteConnected")
        subscribeToPlayerState()
        subscribeToCapabilityChanges()
        getPlayerState()
    }
    
    private func subscribeToPlayerState() {
        guard (!subscribedToPlayerState) else { return }
        appRemote?.playerAPI!.delegate = self
        appRemote?.playerAPI?.subscribe { (_, error) -> Void in
            guard error == nil else { return }
            self.subscribedToPlayerState = true
        }
    }
    
    private func subscribeToCapabilityChanges() {
        guard (!subscribedToCapabilities) else { return }
        appRemote?.userAPI?.delegate = self
        appRemote?.userAPI?.subscribe(toCapabilityChanges: { (success, error) in
            guard error == nil else { return }

            self.subscribedToCapabilities = true
        })
    }
    
    private func getPlayerState() {
        appRemote?.playerAPI?.getPlayerState { (result, error) -> Void in
            guard error == nil else { return }

            print("player state changed")
        }
    }
    
    func appRemoteDisconnect() {
        print("appRemoteDisconnect()")
        self.subscribedToPlayerState = false
        self.subscribedToCapabilities = false
    }
    
}

extension LogInViewController: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
       self.playerState = playerState
    }
}

extension LogInViewController: SPTAppRemoteUserAPIDelegate {
    func userAPI(_ userAPI: SPTAppRemoteUserAPI, didReceive capabilities: SPTAppRemoteUserCapabilities) {
    
    }
}


