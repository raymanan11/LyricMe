
import UIKit
import SafariServices
import AVFoundation
import Alamofire
import SwiftKeychainWrapper

class LogInViewController: UIViewController {
    @IBOutlet weak var logIn: UIButton!
    
    var sceneDelegate = SceneDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let accessToken: String? = KeychainWrapper.standard.string(forKey: Constants.accessToken)
        if accessToken != nil {
            // go straight to main VC to check if access token is valid or not
            // if not valid, call refresh token
            // if is, then use it to get currently playing info
            print(#function)
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let mainViewController = storyBoard.instantiateViewController(withIdentifier: "main") as! MainViewController
            self.navigationController?.pushViewController(mainViewController, animated: false)
        }
    }
    
    @IBAction func logIn(_ sender: Any) {
        sceneDelegate.login()
    }
    
    @objc func moveToNextVC() {
        performSegue(withIdentifier: Constants.goToMainVC, sender: self)
    }
    
}


