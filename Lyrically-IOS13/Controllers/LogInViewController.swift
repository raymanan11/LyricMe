
import UIKit
import StoreKit

class LogInViewController: UIViewController, SKStoreProductViewControllerDelegate {
    
    var sceneDelegate = SceneDelegate()
    var alertManager = AlertManager()
    
    var oneMainVC: UIViewController!
    
    @IBOutlet weak var logInButton: UIButton!
    
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
        
        navigationController?.isNavigationBarHidden = true
        
        let defaults = UserDefaults.standard
        if defaults.initiatedSession {
            hideLogInButton()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideLogInButton), name: NSNotification.Name(rawValue: "openSpotify"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLogInButton), name: NSNotification.Name(rawValue: "closedSpotify"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.enableLogInButton), name: NSNotification.Name(rawValue: "enableLogIn"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.disableLogInButton), name: NSNotification.Name(rawValue: "disableLogIn"), object: nil)
    }
    
    @IBAction func logIn(_ sender: Any) {
        sceneDelegate.login()
        checkIfSpotifyIsInstalled()
    }
    
    @objc func moveToNextVC() {
        performSegue(withIdentifier: Constants.goToMainVC, sender: self)
    }
    
    @objc func hideLogInButton() {
        logInButton.isHidden = true
    }
    
    @objc func showLogInButton() {
        logInButton.isHidden = false
    }
    
    @objc func disableLogInButton() {
        logInButton.isEnabled = false
    }
    
    @objc func enableLogInButton() {
        logInButton.isEnabled = true
    }
    
    func checkIfSpotifyIsInstalled() {
        if appRemote?.isConnected == false {
            if appRemote?.authorizeAndPlayURI(playURI) == false {
                print("Spotify is not installed, showing app store to download spotify")
                alertManager.showAppStoreInstall(view: view, vc: self)
            }
        }
    }

}


