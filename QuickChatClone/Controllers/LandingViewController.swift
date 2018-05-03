//
//  ViewController.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/21/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit

class LandingViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    private struct Storyboard {
        static let welcomeVC = "WelcomeVC"
        static let navigationVC = "NavigationVC"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let userInformation = UserDefaults.standard.dictionary(forKey: "userInformation") {
            let email = userInformation["email"] as! String
            let password = userInformation["password"] as! String
            User.loginUser(withEmail: email, password: password) { [weak weakSelf = self](status) in
                DispatchQueue.main.async {
                    if status {
                        let vc = weakSelf?.storyboard?.instantiateViewController(withIdentifier: Storyboard.navigationVC) as! NavigationViewController
                        weakSelf?.present(vc, animated: true, completion: nil)
                    }else{
                        let vc = weakSelf?.storyboard?.instantiateViewController(withIdentifier: Storyboard.welcomeVC) as! WelcomeViewController
                        weakSelf?.present(vc, animated: true, completion: nil)
                    }
                }
            }
        }else{
            let vc = storyboard?.instantiateViewController(withIdentifier: Storyboard.welcomeVC) as! WelcomeViewController
            present(vc, animated: true, completion: nil)
        }
    }

}

