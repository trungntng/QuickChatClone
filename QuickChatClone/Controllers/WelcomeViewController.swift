//
//  WelcomeViewController.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/21/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    private struct Storyboard {
        static let navigationVC = "NavigationVC"
    }
    
    //MARK: - Variables
    var loginViewTopConstraint: NSLayoutConstraint!
    var registerViewTopConstraint: NSLayoutConstraint!
    var isLoginViewVisible = true
    
    //MARK: - IBOutlet & IBAction
    @IBOutlet weak var cloudsView: UIImageView!
    @IBOutlet weak var cloudsViewLeading: NSLayoutConstraint!
    @IBOutlet weak var switchViewButton: UIButton!
    @IBOutlet weak var darkView: UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet var registerView: UIView!
    @IBOutlet var loginView: UIView!
    @IBOutlet weak var profilePicView: UIImageView!
    @IBOutlet weak var registerNameField: UITextField!
    @IBOutlet weak var registerEmailField: UITextField!
    @IBOutlet weak var registerPasswordField: UITextField!
    @IBOutlet var warningLabels: [UILabel]!
    @IBOutlet weak var loginEmailField: UITextField!
    @IBOutlet weak var loginPasswordField: UITextField!
    @IBOutlet var inputFields: [UITextField]!
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        guard let name = registerNameField.text, let email = registerEmailField.text, let password = registerPasswordField.text else {
            return
        }
        
        for item in inputFields {
            item.resignFirstResponder()
        }
        
        showLoading(state: true)
        
        User.registerUser(withName: name, email: email, password: password, profilePic: profilePicView.image!) { [weak weakSelf = self] (status) in
            DispatchQueue.main.async {
                weakSelf?.showLoading(state: false)
                for item in (weakSelf?.inputFields)! {
                    item.text = ""
                }
                if status == true {
                    let navVC = weakSelf?.storyboard?.instantiateViewController(withIdentifier: Storyboard.navigationVC) as! NavigationViewController
                    weakSelf?.present(navVC, animated: true, completion: nil)
                    weakSelf?.profilePicView.image = UIImage(named: "profile pic")
                }else{
                    for item in (weakSelf?.warningLabels)! {
                        item.isHidden = false
                    }
                }
            }
        }
        
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = loginEmailField.text, let password = loginPasswordField.text else {
            return
        }
        
        for item in inputFields {
            item.resignFirstResponder()
        }
        
        showLoading(state: true)
        
        User.loginUser(withEmail: email, password: password) { [weak weakSelf = self] (status) in
            DispatchQueue.main.async {
                weakSelf?.showLoading(state: false)
                
                for item in (weakSelf?.inputFields)! {
                    item.text = ""
                }
                
                if status == true {
                    let navVC = weakSelf?.storyboard?.instantiateViewController(withIdentifier: Storyboard.navigationVC) as! NavigationViewController
                    weakSelf?.present(navVC, animated: true, completion: nil)
                }else{
                    for item in (weakSelf?.warningLabels)! {
                        item.isHidden = false
                    }
                }
            }
        }
    }
    
    @IBAction func switchViews(_ sender: UIButton) {
        if isLoginViewVisible {
            //Login -> Register
            switchViewButton.setTitle("Sign In", for: .normal)
            loginViewTopConstraint.constant = 1000
            registerViewTopConstraint.constant = 120
            
        }else{
            //Register -> Login
            switchViewButton.setTitle("Create New Account", for: .normal)
            loginViewTopConstraint.constant = 120
            registerViewTopConstraint.constant = 1000
        }
        isLoginViewVisible = !isLoginViewVisible
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        warningLabels.forEach { (label) in
            label.isHidden = true
        }
    }
    
    
    //MARK: - UI
    //Register_Login_View
    private func setupUI() {
        darkView.alpha = 0
        profilePicView.layer.borderColor = UIColor.blue.cgColor
        profilePicView.layer.borderWidth = 2
        profilePicView.layer.cornerRadius = profilePicView.bounds.width / 2.0
        profilePicView.layer.masksToBounds = true
        view.insertSubview(loginView, belowSubview: cloudsView)
        view.insertSubview(registerView, belowSubview: cloudsView)
        loginView.translatesAutoresizingMaskIntoConstraints = false
        loginView.layer.cornerRadius = 8
        loginViewTopConstraint = NSLayoutConstraint(item: loginView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 120)
        NSLayoutConstraint.activate([
            loginViewTopConstraint,
            loginView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            loginView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
            ])
        registerView.translatesAutoresizingMaskIntoConstraints = false
        registerView.layer.cornerRadius = 8
        registerViewTopConstraint = NSLayoutConstraint(item: registerView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 1000)
        NSLayoutConstraint.activate([
            registerViewTopConstraint,
            registerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            registerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            registerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
            ])
    }
    
    //cloudsView
    private func cloudsAnimation(){
        cloudsViewLeading.constant = view.bounds.width - cloudsView.bounds.width
        UIView.animate(withDuration: 15, delay: 0, options: [.repeat, .curveLinear], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    //MARK: - Private functions
    private func showLoading(state: Bool) {
        if state {
            darkView.isHidden = false
            spinner.startAnimating()
            UIView.animate(withDuration: 0.3) {
                self.darkView.alpha = 0.5
            }
        }else{
            UIView.animate(withDuration: 0.3, animations: {
                self.darkView.alpha = 0
            }) { (_) in
                self.spinner.stopAnimating()
                self.darkView.isHidden = true
            }
        }
    }
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        profilePicView.isUserInteractionEnabled = true
        profilePicView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectPicture)))
        for item in inputFields {
            item.delegate = self
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cloudsAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cloudsViewLeading.constant = 0
        view.layoutIfNeeded()
    }
}

//MARK: - UIImagePickerControllerDelegate
extension WelcomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc func selectPicture() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectedImage: UIImage?
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImage = image
        }else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = image
        }
        profilePicView.image = selectedImage
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension WelcomeViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        for item in warningLabels {
            item.isHidden = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
