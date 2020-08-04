
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

        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: Constants.Segues.successfulLogIn), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideLogInButton), name: NSNotification.Name(rawValue: Constants.LogInVC.hideLogIn), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLogInButton), name: NSNotification.Name(rawValue: Constants.LogInVC.showLogIn), object: nil)

    }
    
    @IBAction func logIn(_ sender: Any) {
        sceneDelegate.login()
        checkIfSpotifyIsInstalled()
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
    
    func checkIfSpotifyIsInstalled() {
        if appRemote?.isConnected == false {
            if appRemote?.authorizeAndPlayURI(playURI) == false {
                alertManager.showAppStoreInstall(view: view, vc: self)
            }
        }
    }

}


