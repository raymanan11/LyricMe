
import UIKit
import SafariServices
import AVFoundation
import Alamofire

class LogInViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    var auth = SPTAuth.defaultInstance()!
    var loginUrl: URL?
    var response: URL?
    var currentlyPlaying = CurrentlyPlayingManager()
    
    @IBOutlet weak var logIn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.moveToNextVC), name: NSNotification.Name(rawValue: "logInSuccessful"), object: nil)

    }
    
    func setup() {
        let redirectURL = "Lyrically://"
        auth.redirectURL = URL(string: redirectURL)
        auth.clientID = Constants.clientID
        auth.requestedScopes = ["user-read-currently-playing", "user-read-playback-state"]
        loginUrl = auth.spotifyWebAuthenticationURL()
        loginUrl = URL(string: (loginUrl?.absoluteString.replacingOccurrences(of: "token", with: "code"))!)
    }
    
    func getToken() {
        let parameters = ["client_id" : auth.clientID, "client_secret" : Constants.clientSecret , "grant_type" : "authorization_code", "code" : Constants.code, "redirect_uri" : auth.redirectURL.absoluteString]
        AF.request("https://accounts.spotify.com/api/token", method: .post, parameters: parameters).responseJSON(completionHandler: {
            response in

            if let result = response.value {
                let jsonData = result as! NSDictionary
                AuthService.instance.tokenId = jsonData.value(forKey: "access_token") as? String
                AuthService.instance.sessiontokenId = jsonData.value(forKey: "refresh_token") as? String
            }
        })
    }
    
    @IBAction func logIn(_ sender: Any) {
        if let url = loginUrl {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
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


