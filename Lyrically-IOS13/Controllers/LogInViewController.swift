
import UIKit
import SafariServices
import AVFoundation
import Alamofire
import SwiftKeychainWrapper

class LogInViewController: UIViewController {
    
    var sceneDelegate = SceneDelegate()
    
    @IBOutlet weak var logInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if defaults.initiatedSession {
            hideLogInButton()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideLogInButton), name: NSNotification.Name(rawValue: "openSpotify"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLogInButton), name: NSNotification.Name(rawValue: "spotifyClosed"), object: nil)
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
    
    @IBAction func logIn(_ sender: Any) {
        sceneDelegate.login()
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
    
    @objc func showMainVC() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyBoard.instantiateViewController(withIdentifier: "main") as! MainViewController
        self.navigationController?.pushViewController(mainViewController, animated: false)
    }
    
}


