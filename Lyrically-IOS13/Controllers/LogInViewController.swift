
import UIKit
import StoreKit
import AVFoundation
import SafariServices
import SwiftKeychainWrapper

class LogInViewController: UIViewController, SKStoreProductViewControllerDelegate {
    
    let initiatedSession: Bool? = KeychainWrapper.standard.bool(forKey: Constants.initiatedSession)
    
    let spotifyInstalled: Bool? = KeychainWrapper.standard.bool(forKey: Constants.spotifyInstalled)
    
    var sceneDelegate = SceneDelegate()
    var alertManager = AlertManager()
    
    var spotifyAuthWebView: SFSafariViewController?
    
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var lyricMeLogo: UIImageView!
    
    private let playURI = "spotify:track:1mea3bSkSGXuIRvnydlB5b"
    
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
        
        print("In LogInVC")
        
        navigationController?.isNavigationBarHidden = true
        
//        showLogo()
//        showLogInButton()
//        hideLogInButton()

        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: Constants.Segues.successfulLogIn), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.dismissWebLogIn), name: NSNotification.Name(rawValue: "dismissWebLogin"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideLogInButton), name: NSNotification.Name(rawValue: Constants.LogInVC.hideLogIn), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLogInButton), name: NSNotification.Name(rawValue: Constants.LogInVC.showLogIn), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideLogo), name: NSNotification.Name(rawValue: "hideLogo"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLogo), name: NSNotification.Name(rawValue: "showLogo"), object: nil)
    

    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Segues.successfulLogIn), object: nil)
//
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "dismissWebLogin"), object: nil)
//
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.LogInVC.hideLogIn), object: nil)
//
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.LogInVC.showLogIn), object: nil)
//
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "showLogo"), object: nil)
//
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "hideLogo"), object: nil)
//
//    }
    
    @IBAction func logIn(_ sender: Any) {
        
        if let safeSpotifyInstallled = spotifyInstalled, safeSpotifyInstallled {
            sceneDelegate.login()
        }
        else {
            let scopes = "user-modify-playback-state%20user-read-currently-playing%20user-read-playback-state%20app-remote-control"
            let spotifyWebLogIn = "https://accounts.spotify.com/authorize?response_type=code&client_id=\(Constants.clientID)&redirect_uri=\(Constants.stringRedirectURI)&scope=\(scopes)"
            if let url = URL(string: spotifyWebLogIn) {
                spotifyAuthWebView = SFSafariViewController(url: url)
                present(spotifyAuthWebView!, animated: true, completion: nil)
            }
        }
    }
    
    @objc func moveToNextVC() {
        performSegue(withIdentifier: Constants.Segues.goToMainVC, sender: self)
    }
    
    @objc func hideLogInButton() {
        print("hiding login")
        logInButton.isHidden = true
    }
    
    @objc func showLogInButton() {
        print("showing login")
        logInButton.isHidden = false
    }
    
    @objc func hideLogo() {
        print("hide logo")
        lyricMeLogo.isHidden = true
    }
    
    @objc func showLogo() {
        print("show logo")
        lyricMeLogo.isHidden = false
    }
    
    @objc func dismissWebLogIn() {
        if let safeWebLogin = spotifyAuthWebView {
            safeWebLogin.dismiss(animated: true, completion: nil)
        }
    }
    
    func checkIfSpotifyIsInstalled() {
        if appRemote?.isConnected == false {
            if appRemote?.authorizeAndPlayURI(playURI) == false {
                alertManager.showAppStoreInstall(view: view, vc: self)
            }
        }
    }
    
    private func isSpotifyAppActive() {
        if (AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint) {
            SPTAppRemote.checkIfSpotifyAppIsActive { (isPlaying) in
                if isPlaying {
                    print("Spotify is playing")
                    KeychainWrapper.standard.set(true, forKey: Constants.initiatedSession)
                    print("hiding buttons")
                    self.hideLogInButton()
                    self.hideLogo()
                }
                else {
                    print("audio is playing but not spotify audio")
                    KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
                    self.showLogInButton()
                    self.showLogo()
                }
            }
        }
        else {
            print("spotify app is not active")
            KeychainWrapper.standard.set(false, forKey: Constants.initiatedSession)
            self.showLogo()
            self.showLogInButton()
        }
    }

}


