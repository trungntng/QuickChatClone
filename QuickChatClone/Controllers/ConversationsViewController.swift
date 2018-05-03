//
//  ConversationsViewController.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/22/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit
import Firebase
import AudioToolbox

class ConversationsViewController: UITableViewController {
    
    lazy var leftButton: UIBarButtonItem = {
        let image = UIImage(named: "default profile")?.withRenderingMode(.alwaysOriginal)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(showProfile))
        return button
    }()
    var items = [Conversation]()
    var selectedUser: User?
    
    //MARK: - selector functions
    @objc func showContacts(){
        let info = ["viewType": ShowExtraViews.contacts]
        NotificationCenter.default.post(name: NSNotification.Name.init("showExtraViews"), object: nil, userInfo: info)
    }
    
    @objc func showProfile(){
        let info = ["viewType": ShowExtraViews.profile]
        NotificationCenter.default.post(name: NSNotification.Name.init("showExtraViews"), object: nil, userInfo: info)
        inputView?.isHidden = true
    }
    
    @objc func showUserMessages(notification: NSNotification){
        if let user = notification.userInfo?["user"] as? User {
            selectedUser = user
            performSegue(withIdentifier: "ChatSegue", sender: self)
        }
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatSegue" {
            let vc = segue.destination as! ChatViewController
            vc.currentUser = selectedUser
        }
    }
    
    //MARK: - Internal functions
    func fetchData(){
        Conversation.showConversations { (conversations) in
            self.items = conversations
            self.items.sort{$0.lastMessage.timestamp > $1.lastMessage.timestamp}
            DispatchQueue.main.async {
                self.tableView.reloadData()
                for conversation in self.items {
                    if conversation.lastMessage.isRead == false {
                        self.playSound()
                        break
                    }
                }
            }
        }
    }
    
    func playSound(){
        var soundURL: NSURL?
        var soundID: SystemSoundID = 0
        let filePath = Bundle.main.path(forResource: "newMessage", ofType: "wav")
        soundURL = NSURL(fileURLWithPath: filePath!)
        AudioServicesCreateSystemSoundID(soundURL!, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    //MARK: - ViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Notification
        NotificationCenter.default.addObserver(self, selector: #selector(showUserMessages), name: NSNotification.Name.init("showUserMessages"), object: nil)
 
        //NavigationItem
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "compose")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(showContacts))
        navigationItem.leftBarButtonItem = leftButton
        if let id = Auth.auth().currentUser?.uid {
            User.info(forUserID: id) { (user) in
                let image = user.profilePic
                let contentSize = CGSize(width: 30, height: 30)
                UIGraphicsBeginImageContextWithOptions(contentSize, false, 0.0)
                UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: contentSize), cornerRadius: 14).addClip()
                image.draw(in: CGRect(origin: CGPoint.zero, size: contentSize))
                let path = UIBezierPath(roundedRect: CGRect(origin: CGPoint.zero, size: contentSize), cornerRadius: 14)
                path.lineWidth = 2
                UIColor.white.setStroke()
                path.stroke()
                let finalImage = UIGraphicsGetImageFromCurrentImageContext()!.withRenderingMode(.alwaysOriginal)
                UIGraphicsEndImageContext()
                DispatchQueue.main.async {
                    self.leftButton.image = finalImage
                }
            }
        }
        
        
        fetchData()
    }

}

extension ConversationsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if items.count == 0 {
            return view.bounds.height - navigationController!.navigationBar.bounds.height
        }else{
            return 80
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if items.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ConversationsTBCell
            cell.clearCellData()
            cell.profilePicture.image = items[indexPath.row].user.profilePic
            cell.nameLabel.text = items[indexPath.row].user.name
            switch items[indexPath.row].lastMessage.type {
            case .text:
                let message = items[indexPath.row].lastMessage.content as! String
                cell.messageLabel.text = message
            case .photo:
                cell.messageLabel.text = "Media"
            case .location:
                cell.messageLabel.text = "Location"
            }
            let messageDate = Date(timeIntervalSince1970: TimeInterval(items[indexPath.row].lastMessage.timestamp))
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            cell.timeLabel.text = dateFormatter.string(from: messageDate)
            if items[indexPath.row].lastMessage.owner == .sender && items[indexPath.row].lastMessage.isRead == false {
                cell.nameLabel.font = UIFont(name:"AvenirNext-DemiBold", size: 17.0)
                cell.messageLabel.font = UIFont(name:"AvenirNext-DemiBold", size: 14.0)
                cell.timeLabel.font = UIFont(name:"AvenirNext-DemiBold", size: 13.0)
                cell.profilePicture.layer.borderColor = UIColor.blue.cgColor
                cell.nameLabel.textColor = .purple
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if items.count > 0 {
            selectedUser = items[indexPath.row].user
            performSegue(withIdentifier: "ChatSegue", sender: self)
        }
    }
}









