//
//  Conversation.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/26/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit
import Firebase

class Conversation {
    let user: User
    var lastMessage: Message
    
    init(user: User, lastMessage: Message) {
        self.user = user
        self.lastMessage = lastMessage
    }
    
    class func showConversations(completion: @escaping ([Conversation]) -> Void){
        if let currentUserID = Auth.auth().currentUser?.uid {
            var conversations = [Conversation]()
            Database.database().reference().child("users").child(currentUserID).child("conversations").observe(.childAdded) { (snapshot) in
                if snapshot.exists() {
                    let fromID = snapshot.key
                    let values = snapshot.value as! [String:String]
                    let location = values["location"]!
                    User.info(forUserID: fromID, completion: { (user) in
                        let emptyMessage = Message(type: .text, content: "loading", owner: .sender, timestamp: 0, isRead: true)
                        let conversation = Conversation(user: user, lastMessage: emptyMessage)
                        conversations.append(conversation)
                        conversation.lastMessage.downloadLastMessage(forLocation: location, completion: {
                            completion(conversations)
                        })
                    })
                }
            }
        }
    }
}
