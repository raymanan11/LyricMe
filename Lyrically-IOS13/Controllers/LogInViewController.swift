
import UIKit
import StoreKit
import SafariServices
import SwiftKeychainWrapper

class LogInViewController: UIViewController, SKStoreProductViewControllerDelegate {
    
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
        
        print("In Log In VC")
        
        navigationController?.isNavigationBarHidden = true
        
        if let safeSpotifyInstalled = spotifyInstalled, safeSpotifyInstalled {
            hideLogInButton()
            hideLogo()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: Constants.Segues.successfulLogIn), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.dismissWebLogIn), name: NSNotification.Name(rawValue: "dismissWebLogin"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideLogInButton), name: NSNotification.Name(rawValue: Constants.LogInVC.hideLogIn), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLogInButton), name: NSNotification.Name(rawValue: Constants.LogInVC.showLogIn), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLogo), name: NSNotification.Name(rawValue: "showLogo"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideLogo), name: NSNotification.Name(rawValue: "hideLogo"), object: nil)

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
//            KeychainWrapper.standard.set(true, forKey: Constants.spotifyInstalled)
            print("defaults.spotifyInstalled = true")
            sceneDelegate.login()
        }
        else {
//            KeychainWrapper.standard.set(false, forKey: Constants.spotifyInstalled)
            print("defaults.spotifyInstalled = false")
            let scopes = "user-modify-playback-state%20user-read-currently-playing%20user-read-playback-state%20app-remote-control"
            let spotifyWebLogIn = "https://accounts.spotify.com/authorize?response_type=code&client_id=\(Constants.clientID)&redirect_uri=\(Constants.stringRedirectURI)&scope=\(scopes)"
            if let url = URL(string: spotifyWebLogIn) {
                spotifyAuthWebView = SFSafariViewController(url: url)
                present(spotifyAuthWebView!, animated: true, completion: nil)
            }
            else {
                print("Invalid spotify log in url")
            }
        }
    }
    
    @objc func moveToNextVC() {
        performSegue(withIdentifier: Constants.Segues.goToMainVC, sender: self)
    }
    
    @objc func hideLogInButton() {
        logInButton.isHidden = true
    }
    
    @objc func showLogInButton() {
        logInButton.isHidden = false
    }
    
    @objc func hideLogo() {
        lyricMeLogo.isHidden = true
    }
    
    @objc func showLogo() {
        lyricMeLogo.isHidden = false
    }
    
    @objc func dismissWebLogIn() {
        print("dismissWebLogIn")
        if let safeWebLogin = spotifyAuthWebView {
            print("Dismissing log in page")
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

}


