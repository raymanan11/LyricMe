
import UIKit
import SafariServices
import AVFoundation
import Alamofire
import SwiftKeychainWrapper

class LogInViewController: UIViewController {
    
    var sceneDelegate = SceneDelegate()
    
    var oneMainVC: UIViewController!
    
    @IBOutlet weak var logInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if defaults.initiatedSession {
            print("initiated bitch")
            hideLogInButton()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.showMainVC), name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideLogInButton), name: NSNotification.Name(rawValue: "openSpotify"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.showLogInButton), name: NSNotification.Name(rawValue: "closedSpotify"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)
    }
    
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
        if oneMainVC == nil {
            print("oneMainVC is nil!")
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            oneMainVC = storyBoard.instantiateViewController(withIdentifier: "main") as! MainViewController
        }
        self.navigationController?.pushViewController(oneMainVC, animated: true)
    }

}


