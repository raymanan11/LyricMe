
import UIKit
import SafariServices
import AVFoundation
import Alamofire

class LogInViewController: UIViewController {
    
    @IBOutlet weak var logIn: UIButton!
    
    var sceneDelegate = SceneDelegate()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        //setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)

    }
    
    @IBAction func logIn(_ sender: Any) {
        sceneDelegate.login()
    }
    
    @objc func moveToNextVC() {
        performSegue(withIdentifier: "goToMainView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMainView" {
            let destinationVC = segue.destination as! MainViewController
        }
    }
    
}


