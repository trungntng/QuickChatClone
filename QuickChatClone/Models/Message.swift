//
//  Message.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/23/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit
import Firebase

class Message {
    
    var owner: MessageOwner
    var type: MessageType
    var content: Any
    var timestamp: Int
    var isRead: Bool
    var image: UIImage?
    private var toID: String?
    private var fromID: String?
    
    init(type: MessageType, content: Any, owner: MessageOwner, timestamp: Int, isRead: Bool) {
        self.type = type
        self.content = content
        self.owner = owner
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    class func downloadAllMessages(forUserID: String, completion: @escaping (Message) -> Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(currentUserID).child("conversations").child(forUserID).observe(.value) { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String:String]
                    let location = data["location"]!
                    Database.database().reference().child("conversations").child(location).observe(.childAdded, with: { (snapshot1) in
                        if snapshot1.exists() {
                            let receivedMessages = snapshot1.value as! [String:Any]
                            let messageType = receivedMessages["type"] as! String
                            var type = MessageType.text
                            switch messageType {
                            case "photo":
                                type = .photo
                            case "location":
                                type = .location
                            default:
                                break
                            }
                            let content = receivedMessages["content"] as! String
                            let fromID = receivedMessages["fromID"] as! String
                            let timestamp = receivedMessages["timestamp"] as! Int
                            if fromID == currentUserID {
                                let message = Message(type: type, content: content, owner: .receiver, timestamp: timestamp, isRead: true)
                                completion(message)
                            }else{
                                let message = Message(type: type, content: content, owner: .sender, timestamp: timestamp, isRead: true)
                                completion(message)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func downloadImage(indexPathRow: Int, completion: @escaping (Bool, Int) -> Void) {
        if self.type == .photo {
            let imageLink = self.content as! String
            let imageURL = URL(string: imageLink)
            URLSession.shared.dataTask(with: imageURL!) { (data, response, error) in
                if error == nil {
                    self.image = UIImage(data: data!)
                    completion(true, indexPathRow)
                }
            }.resume()
        }
    }
    
    class func markMessageRead(forUserID: String){
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(currentUserID).child("conversations").child(forUserID).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String:String]
                    let location = data["location"]!
                    Database.database().reference().child("conversations").child(location).observeSingleEvent(of: .value, with: { (snapshot1) in
                        if snapshot1.exists() {
                            for item in snapshot1.children {
                                let receivedMessage = (item as! DataSnapshot).value as! [String:Any]
                                let fromID = receivedMessage["fromID"] as! String
                                if fromID != currentUserID {
                                    Database.database().reference().child("conversations").child(location).child((item as! DataSnapshot).key).child("isRead").setValue(true)
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func downloadLastMessage(forLocation: String, completion: @escaping () -> Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("conversations").child(forLocation).observe(.value) { (snapshot) in
                if snapshot.exists() {
                    for snap in snapshot.children {
                        let receivedMessage = (snap as! DataSnapshot).value as! [String: Any]
                        self.content = receivedMessage["content"]!
                        self.timestamp = receivedMessage["timestamp"] as! Int
                        let messageType = receivedMessage["type"] as! String
                        let fromID = receivedMessage["fromID"] as! String
                        self.isRead = receivedMessage["isRead"] as! Bool
                        var type = MessageType.text
                        switch messageType {
                        case "text":
                            type = .text
                        case "photo":
                            type = .photo
                        case "location":
                            type = .location
                        default:
                            break
                        }
                        self.type = type
                        if currentUserID == fromID {
                            self.owner = .receiver
                        }else{
                            self.owner = .sender
                        }
                        completion()
                    }
                }
            }
        }
    }
    
    class func send(message: Message, toID: String, completion: @escaping (Bool) -> Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            switch message.type {
            case .location:
                let values = ["type": "location", "content": message.content, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false]
                Message.uploadMessage(withValues: values, toID: toID) { (status) in
                    completion(status)
                }
            case .photo:
                let imageData = UIImageJPEGRepresentation(message.content as! UIImage, 0.5)
                let child = UUID().uuidString
                Storage.storage().reference().child("messagePics").child(child).putData(imageData!, metadata: nil) { (metadata, error) in
                    if error == nil {
                        let path = metadata?.downloadURL()?.absoluteString
                        let values = ["type": "photo", "content": path!, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false] as [String : Any]
                        Message.uploadMessage(withValues: values, toID: toID, completion: { (status) in
                            completion(status)
                        })
                    }
                }
            case .text:
                let values = ["type": "text", "content": message.content, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false]
                Message.uploadMessage(withValues: values, toID: toID) { (status) in
                    completion(status)
                }
                
            }
        }
    }
    
    class func uploadMessage(withValues: [String: Any], toID: String, completion: @escaping (Bool) -> Void){
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(currentUserID).child("conversations").child(toID).observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    let data = snapshot.value as! [String:String]
                    let location = data["location"]!
                    Database.database().reference().child("conversations").child(location).childByAutoId().setValue(withValues, withCompletionBlock: { (error, _) in
                        if error == nil {
                            completion(true)
                        }else{
                            completion(false)
                        }
                    })
                }else{
                    Database.database().reference().child("conversations").childByAutoId().childByAutoId().setValue(withValues, withCompletionBlock: { (error, reference) in
                        let data = ["location": reference.parent!.key]
                        Database.database().reference().child("users").child(currentUserID).child("conversations").child(toID).updateChildValues(data)
                        Database.database().reference().child("users").child(toID).child("conversations").child(currentUserID).updateChildValues(data)
                        completion(true)
                    })
                }
            }
        }
    }
}
