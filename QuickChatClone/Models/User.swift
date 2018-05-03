//
//  User.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/22/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit
import Firebase

class User {
    
    struct UserKeys {
        static let userInformation = "userInformation"
    }
    
    let name: String
    let email: String
    let id: String
    var profilePic: UIImage
    
    //MARK: - Initializers
    init(name: String, email: String, id: String, profilePic: UIImage) {
        self.name = name
        self.email = email
        self.id = id
        self.profilePic = profilePic
    }
    
    //MARK: - Firebase methods
    class func registerUser(withName: String, email: String, password: String, profilePic: UIImage, completion: @escaping (Bool) -> Void) {
        //Create user -> upload image to Storage -> save userInfo (name, email, profilePicLink) to database -> save (email, password) to UserDefaults
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if error == nil {
                user?.sendEmailVerification(completion: nil)
                let storageRef = Storage.storage().reference().child("usersProfilePics").child(user!.uid)
                let imageData = UIImageJPEGRepresentation(profilePic, 0.1)
                storageRef.putData(imageData!, metadata: nil, completion: { (metadata, error) in
                    if error == nil {
                        let path = metadata?.downloadURL()?.absoluteString
                        let values = ["name": withName, "email": email, "profilePicLink": path!]
                        Database.database().reference().child("users").child(user!.uid).child("credentials").updateChildValues(values, withCompletionBlock: { (error, _) in
                            if error == nil {
                                let userInfo = ["email": email, "password": password]
                                UserDefaults.standard.set(userInfo, forKey: UserKeys.userInformation)
                                completion(true)
                            }
                        })
                    }
                })
            }else{
                completion(false)
            }
        }
    }
    
    class func loginUser(withEmail: String, password: String, completion: @escaping (Bool) -> Void){
        Auth.auth().signIn(withEmail: withEmail, password: password) { (user, error) in
            if error == nil {
                let userInfo = ["email": withEmail, "password": password]
                UserDefaults.standard.set(userInfo, forKey: UserKeys.userInformation)
                completion(true)
            }else{
                completion(false)
            }
        }
    }
    
    class func logOutUser(completion: @escaping (Bool) -> Void){
        do{
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: UserKeys.userInformation)
            completion(true)
        }catch{
            completion(false)
        }
    }
    
    class func info(forUserID: String, completion: @escaping (User)->Void){
        Database.database().reference().child("users").child(forUserID).child("credentials").observeSingleEvent(of: .value) { (snapshot) in
            if let data = snapshot.value as? [String:String] {
                let name = data["name"]!
                let email = data["email"]!
                let link = data["profilePicLink"]!
                URLSession.shared.dataTask(with: URL(string: link)!, completionHandler: { (data, response, error) in
                    if error == nil {
                        let profilePic = UIImage(data: data!)
                        let user = User(name: name, email: email, id: forUserID, profilePic: profilePic!)
                        completion(user)
                    }
                }).resume()
            }
        }
    }
    
    class func downloadAllUsers(exceptID: String, completion: @escaping (User)->Void){
        Database.database().reference().child("users").observe(.childAdded) { (snapshot) in
            let id = snapshot.key
            let data = snapshot.value as! [String:Any]
            let credentials = data["credentials"] as! [String:String]
            if id != exceptID {
                let name = credentials["name"]!
                let email = credentials["email"]!
                let link = credentials["profilePicLink"]!
                URLSession.shared.dataTask(with: URL(string: link)!, completionHandler: { (data, response, error) in
                    if error == nil {
                        let profilePic = UIImage(data: data!)
                        let user = User(name: name, email: email, id: id, profilePic: profilePic!)
                        completion(user)
                    }
                }).resume()
            }
        }
    }
    
    class func checkUserVerification(completion: @escaping (Bool)->Void){
        Auth.auth().currentUser?.reload(completion: { (_) in
            let status = (Auth.auth().currentUser?.isEmailVerified)!
            completion(status)
        })
    }
}
