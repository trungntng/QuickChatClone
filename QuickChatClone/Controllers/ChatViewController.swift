//
//  ChatViewController.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/23/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit
import Photos
import Firebase
import CoreLocation

class ChatViewController: UITableViewController {
    
    @IBOutlet var inputBar: UIView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBAction func showOptions(_ sender: Any) {
        animateExtraButtons(toHide: false)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        if let text = inputTextField.text {
            if text.count > 0 {
                composeMessage(type: .text, content: inputTextField.text!)
                inputTextField.text = ""
            }
        }
    }
    
    @IBAction func showMessage(_ sender: Any) {
        animateExtraButtons(toHide: true)
    }
    
    @IBAction func showPhoto(_ sender: Any) {
        animateExtraButtons(toHide: true)
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized || status == .notDetermined {
            imagePicker.sourceType = .savedPhotosAlbum
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func showCamera(_ sender: Any) {
        animateExtraButtons(toHide: true)
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized || status == .notDetermined {
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func showLocation(_ sender: Any) {
        canSendLocation = true
        animateExtraButtons(toHide: true)
        if checkLocationPermission() {
            locationManager.startUpdatingLocation()
        }else{
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    var currentUser: User?
    var items = [Message]()
    let BAR_HEIGHT: CGFloat = 50
    let imagePicker = UIImagePickerController()
    let locationManager = CLLocationManager()
    var canSendLocation = true
    override var inputAccessoryView: UIView? {
        get {
            inputBar.frame.size.height = BAR_HEIGHT
            inputBar.clipsToBounds = true
            return inputBar
        }
    }
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    //MARK: - Internal functions
    func composeMessage(type: MessageType, content: Any){
        let message = Message(type: type, content: content, owner: .sender, timestamp: Int(Date().timeIntervalSince1970), isRead: false)
        Message.send(message: message, toID: currentUser!.id) { (_) in
            //NULL
        }
    }
    
    private func fetchData() {
        Message.downloadAllMessages(forUserID: currentUser!.id) { (message) in
            self.items.append(message)
            self.items.sort { $0.timestamp < $1.timestamp }
            DispatchQueue.main.async {
                if !self.items.isEmpty {
                    self.tableView.reloadData()
                    self.tableView.scrollToRow(at: IndexPath(row: self.items.count - 1, section: 0), at: .bottom, animated: true)
                }
            }
        }
        Message.markMessageRead(forUserID: currentUser!.id)
    }
    
    func animateExtraButtons(toHide: Bool){
        switch toHide {
        case true:
            bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.inputBar.layoutIfNeeded()
            }
        default:
            bottomConstraint.constant = -50
            UIView.animate(withDuration: 0.3) {
                self.inputBar.layoutIfNeeded()
            }
        }
    }
    
    func checkLocationPermission() -> Bool {
        var state = false
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            state = true
        case .authorizedAlways:
            state = true
        default: break
        }
        return state
    }
    
    //MARK: - Selector functions
    @objc func dismissSelf(){
        if let navController = navigationController {
            navController.popViewController(animated: true)
        }
    }
    
    @objc func showKeyboard(notification: NSNotification){
        if let frame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let height = frame.cgRectValue.height
            tableView.contentInset.bottom = height
            tableView.scrollIndicatorInsets.bottom = height
            if items.count > 0 {
                tableView.scrollToRow(at: IndexPath(row: items.count - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }

    //MARK: - ViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UITableView
        tableView.estimatedRowHeight = BAR_HEIGHT
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.contentInset.bottom = BAR_HEIGHT
        tableView.scrollIndicatorInsets.bottom = BAR_HEIGHT
        
        //Navigation
        navigationItem.title = currentUser?.name
        navigationItem.setHidesBackButton(true, animated: false)
        let icon = UIImage(named: "back")?.withRenderingMode(.alwaysOriginal)
        let backButton = UIBarButtonItem(image: icon!, style: .plain, target: self, action: #selector(dismissSelf))
        navigationItem.leftBarButtonItem = backButton
        
        //Delegate
        imagePicker.delegate = self
        locationManager.delegate = self
        
        fetchData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputBar.backgroundColor = .clear
        view.layoutIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        Message.markMessageRead(forUserID: currentUser!.id)
    }
    
}

extension ChatViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isDragging {
            tableView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.3) {
                tableView.transform = CGAffineTransform.identity
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch items[indexPath.row].owner {
        case .receiver:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReceiverCell", for: indexPath) as! ReceiverCell
            cell.clearCellData()
            switch items[indexPath.row].type {
            case .text:
                cell.message.text = items[indexPath.row].content as! String
            case .photo:
                if let image = items[indexPath.row].image {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                }else{
                    cell.messageBackground.image = UIImage(named: "loading")
                    items[indexPath.row].downloadImage(indexPathRow: indexPath.row) { (status, index) in
                        if status == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            case .location:
                cell.messageBackground.image = UIImage(named: "location")
                cell.message.isHidden = true
            }
            return cell
        case .sender:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SenderCell", for: indexPath) as! SenderCell
            cell.clearCellData()
            cell.profilePic.image = currentUser?.profilePic
            switch items[indexPath.row].type {
            case .text:
                cell.message.text = items[indexPath.row].content as! String
            case .photo:
                if let image = items[indexPath.row].image {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                }else{
                    cell.messageBackground.image = UIImage(named: "loading")
                    items[indexPath.row].downloadImage(indexPathRow: indexPath.row) { (status, index) in
                        if status == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            case .location:
                cell.messageBackground.image = UIImage(named: "location")
                cell.message.isHidden = true
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        inputTextField.resignFirstResponder()
        switch items[indexPath.row].type {
        case .photo:
            if let photo = items[indexPath.row].image {
                let info = ["viewType": ShowExtraViews.preview, "pic": photo] as [String:Any]
                NotificationCenter.default.post(name: NSNotification.Name.init("showExtraViews"), object: nil, userInfo: info)
                self.inputAccessoryView?.isHidden = true
            }
        case .location:
            let coordinates = (items[indexPath.row].content as! String).components(separatedBy: ":")
            let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(coordinates[0])!, longitude: CLLocationDegrees(coordinates[1])!)
            let info = ["viewType": ShowExtraViews.map, "location": location] as [String:Any]
            NotificationCenter.default.post(name: NSNotification.Name.init("showExtraViews"), object: nil, userInfo: info)
            inputAccessoryView?.isHidden = true
        default:
            break
        }
    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            composeMessage(type: .photo, content: pickedImage)
        }else if let pickerImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            composeMessage(type: .photo, content: pickerImage)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ChatViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        if let lastLocation = locations.last {
            if canSendLocation {
                let coordinate = String(lastLocation.coordinate.latitude) + ":" + String(lastLocation.coordinate.longitude)
                let message = Message(type: .location, content: coordinate, owner: .sender, timestamp: Int(Date().timeIntervalSince1970), isRead: false)
                Message.send(message: message, toID: currentUser!.id) { (_) in
                    self.canSendLocation = false
                }
            }
        }
    }
}
