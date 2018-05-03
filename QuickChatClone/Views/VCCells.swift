//
//  VCCells.swift
//  QuickChatClone
//
//  Created by Trung Trinh on 4/22/18.
//  Copyright © 2018 Trung Trinh. All rights reserved.
//

import UIKit

class SenderCell: UITableViewCell {
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var messageBackground: UIImageView!
    @IBOutlet weak var message: UITextView!
    
    func clearCellData(){
        message.text = nil
        message.isHidden = false
        messageBackground.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        message.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5)
        messageBackground.layer.cornerRadius = 15
        messageBackground.clipsToBounds = true
        
        profilePic.layer.cornerRadius = profilePic.bounds.width / 2.0
        profilePic.clipsToBounds = true
    }
}

class ReceiverCell: UITableViewCell {
    @IBOutlet weak var messageBackground: UIImageView!
    @IBOutlet weak var message: UITextView!
    
    func clearCellData(){
        message.text = nil
        message.isHidden = false
        messageBackground.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        message.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5)
        messageBackground.layer.cornerRadius = 15
        messageBackground.clipsToBounds = true
    }

}

class ConversationsTBCell: UITableViewCell {
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func clearCellData(){
        nameLabel.font = UIFont(name:"AvenirNext-Regular", size: 17.0)
        messageLabel.font = UIFont(name:"AvenirNext-Regular", size: 14.0)
        timeLabel.font = UIFont(name:"AvenirNext-Regular", size: 13.0)
        profilePicture.layer.borderColor = UIColor.blue.cgColor
        profilePicture.layer.borderWidth = 2
        profilePicture.layer.cornerRadius = profilePicture.bounds.width/2.0
        profilePicture.clipsToBounds = true
        messageLabel.textColor = UIColor(red: 111/255.0, green: 113/255.0, blue: 121/255.0, alpha: 1)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class ContactsCVCell: UICollectionViewCell {
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
}
