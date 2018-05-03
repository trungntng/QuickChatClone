//
//  NavigationViewController.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/22/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class NavigationViewController: UINavigationController {
    
    //MARK: - Variables
    let darkView = UIView()
    var containerTopConstraint: NSLayoutConstraint!
    var items = [User]()
    
    //MARK: - IBOutlet & IBAction
    @IBOutlet var contactsView: UIView!
    @IBOutlet var profileView: UIView!
    @IBOutlet var previewView: UIView!
    @IBOutlet var mapPreviewView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismissExtraViews()
    }
    
    @IBAction func logOutButtonTapped(_ sender: UIButton) {
        User.logOutUser { (status) in
            if status == true {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    //MARK: - Show/Dismiss ExtraViewsContainer
    @objc func showExtraViews(notification: NSNotification){
        let transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        containerTopConstraint.constant = 0
        darkView.isHidden = false
        if let type = notification.userInfo?["viewType"] as? ShowExtraViews {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                self.darkView.alpha = 0.8
                if (type == .contacts || type == .profile){
                    self.view.transform = transform
                }
            }, completion: nil)
            
            switch type {
            case .contacts:
                contactsView.isHidden = false
            case .profile:
                profileView.isHidden = false
            case .preview:
                previewView.isHidden = false
                previewImageView.image = notification.userInfo?["pic"] as? UIImage
                scrollView.contentSize = previewImageView.frame.size
            case .map:
                mapPreviewView.isHidden = false
                let coordinate = notification.userInfo?["location"] as? CLLocationCoordinate2D
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate!
                mapView.addAnnotation(annotation)
                mapView.showAnnotations(mapView.annotations, animated: false)
            }
        }
    }
    
    func dismissExtraViews(){
        containerTopConstraint.constant = 1000
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
            self.darkView.alpha = 0
            self.view.transform = CGAffineTransform.identity
        }) { (_) in
            self.darkView.isHidden = true
            self.profileView.isHidden = true
            self.contactsView.isHidden = true
            self.previewView.isHidden = true
            self.mapPreviewView.isHidden = true
            self.mapView.removeAnnotations(self.mapView.annotations)
            let vc = self.viewControllers.last
            vc?.inputAccessoryView?.isHidden = false
        }
    }
    
    //MARK: - Firebase
    private func fetchUsers(){
        if let id = Auth.auth().currentUser?.uid {
            User.downloadAllUsers(exceptID: id) { (user) in
                DispatchQueue.main.async {
                    self.items.append(user)
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    private func fetchUserInfo(){
        if let id = Auth.auth().currentUser?.uid {
            User.info(forUserID: id) { (user) in
                DispatchQueue.main.async {
                    self.nameLabel.text = user.name
                    self.emailLabel.text = user.email
                    self.profilePicImageView.image = user.profilePic
                }
            }
        }
    }
    
    //MARK: - UI
    private func setupUI(){
        //DarkView
        view.addSubview(darkView)
        darkView.translatesAutoresizingMaskIntoConstraints = false
        darkView.backgroundColor = .black
        darkView.alpha = 0
        darkView.isHidden = true
        NSLayoutConstraint.activate([
            darkView.topAnchor.constraint(equalTo: view.topAnchor),
            darkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            darkView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            darkView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        //ContainerView
        let extraViewsContainer = UIView()
        extraViewsContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(extraViewsContainer)
        extraViewsContainer.backgroundColor = .clear
        containerTopConstraint = NSLayoutConstraint(item: extraViewsContainer, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 1000)
        NSLayoutConstraint.activate([
            containerTopConstraint,
            extraViewsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            extraViewsContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            extraViewsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
        //ContactsView
        extraViewsContainer.addSubview(contactsView)
        contactsView.translatesAutoresizingMaskIntoConstraints = false
        contactsView.isHidden = true
        contactsView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        NSLayoutConstraint.activate([
            contactsView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor),
            contactsView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor),
            contactsView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor),
            contactsView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor)
            ])
        //ProfileView
        extraViewsContainer.addSubview(profileView)
        profileView.translatesAutoresizingMaskIntoConstraints = false
        profileView.layer.cornerRadius = 5
        profileView.clipsToBounds = true
        profileView.isHidden = true
        profilePicImageView.layer.borderColor = UIColor.blue.cgColor
        profilePicImageView.layer.borderWidth = 3
        profilePicImageView.layer.cornerRadius = profilePicImageView.bounds.width / 2.0
        profilePicImageView.clipsToBounds = true
        NSLayoutConstraint.activate([
            profileView.heightAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width * 0.9)),
            NSLayoutConstraint(item: profileView, attribute: .width, relatedBy: .equal, toItem: profileView, attribute: .height, multiplier: 0.8125, constant: 0),
            profileView.centerXAnchor.constraint(equalTo: extraViewsContainer.centerXAnchor),
            profileView.centerYAnchor.constraint(equalTo: extraViewsContainer.centerYAnchor)
            ])
        view.layoutIfNeeded()
        //PreviewView
        extraViewsContainer.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.isHidden = true
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor),
            previewView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor),
            previewView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor)
            ])
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        //MapView
        extraViewsContainer.addSubview(mapPreviewView)
        mapPreviewView.translatesAutoresizingMaskIntoConstraints = false
        mapPreviewView.isHidden = true
        NSLayoutConstraint.activate([
            mapPreviewView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor),
            mapPreviewView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor),
            mapPreviewView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor),
            mapPreviewView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor)
            ])
    }
    
    
    //MARK: - ViewController lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(showExtraViews), name: NSNotification.Name.init("showExtraViews"), object: nil)
        fetchUsers()
        fetchUserInfo()
    }
}




//MARK: - UICollectionView
extension NavigationViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if items.count == 0 {
            return 1
        }else{
            return items.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if items.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath)
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ContactsCVCell
            cell.profilePic.image = items[indexPath.row].profilePic
            cell.nameLabel.text = items[indexPath.row].name
            cell.profilePic.layer.borderWidth = 2
            cell.profilePic.layer.borderColor = UIColor.blue.cgColor
            cell.profilePic.layer.cornerRadius = cell.profilePic.bounds.width / 2.0
            cell.profilePic.clipsToBounds = true
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if items.count == 0 {
            return collectionView.bounds.size
        }else{
            if UIScreen.main.bounds.width > UIScreen.main.bounds.height {
                let width = (0.3 * UIScreen.main.bounds.height)
                let height = width + 30
                return CGSize(width: width, height: height)
            }else{
                let width = (0.3 * UIScreen.main.bounds.width)
                let height = width + 30
                return CGSize(width: width, height: height)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if items.count > 0 {
            dismissExtraViews()
            let userInfo = ["user": items[indexPath.row]]
            NotificationCenter.default.post(name: NSNotification.Name.init("showUserMessages"), object: nil, userInfo: userInfo)
        }
    }
}

extension NavigationViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return previewImageView
    }
}

