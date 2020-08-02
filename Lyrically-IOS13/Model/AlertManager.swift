//
//  AlertManager.swift
//  Lyrically-IOS13
//
//  Created by Raymond An on 8/1/20.
//  Copyright © 2020 Raymond An. All rights reserved.
//

import Foundation
import StoreKit

class AlertManager: NSObject, SKStoreProductViewControllerDelegate {
    
    func showAppStoreInstall(view: UIView, vc: UIViewController) {
        if TARGET_OS_SIMULATOR != 0 {
            presentAlert(title: "Simulator In Use", message: "The App Store is not available in the iOS simulator, please test this feature on a physical device.", vc: vc)
        }
        else {
            let loadingView = UIActivityIndicatorView(frame: view.bounds)
            view.addSubview(loadingView)
            loadingView.startAnimating()
            loadingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            let storeProductViewController = SKStoreProductViewController()
            storeProductViewController.delegate = self
            storeProductViewController.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: SPTAppRemote.spotifyItunesItemIdentifier()], completionBlock: { (success, error) in
                loadingView.removeFromSuperview()
                if let error = error {
                    self.presentAlert(
                        title: "Error accessing App Store",
                        message: error.localizedDescription, vc: vc)
                } else {
                    vc.present(storeProductViewController, animated: true, completion: nil)
                }
            })
        }
    }
    
    func presentAlert(title: String, message: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        DispatchQueue.main.asyncAfter(deadline: 1.second.fromNow) {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
}
