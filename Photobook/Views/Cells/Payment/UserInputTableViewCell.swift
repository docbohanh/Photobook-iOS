//
//  UserInputTableViewCell.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 18/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class UserInputTableViewCell: UITableViewCell {
    
    struct Constants {
        static let errorColor = UIColor(red:1, green:0.23, blue:0.19, alpha:1)
        static let messageColor = UIColor(red:0.43, green:0.43, blue:0.45, alpha:1)
        static let requiredText = NSLocalizedString("UserInputRequired", value: "Required", comment: "User input required")
    }

    @IBOutlet weak var separatorLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var topSeparator: UIView!
    @IBOutlet weak var messageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var textFieldLeadingConstraint: NSLayoutConstraint!
    var message: String? {
        didSet{
            if messageLabel.text != message{
                messageLabel.alpha = 0
                messageLabel.text = message
                messageLabel.textAlignment = .left
            }
            
            guard message != nil else{
                self.messageBottomConstraint.constant = 0
                return
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                self.messageLabel.alpha = 1
                self.messageLabel.textColor = Constants.messageColor
            })
        }
    }
    var errorMessage: String? {
        didSet{
            if messageLabel.text != errorMessage{
                messageLabel.alpha = 0
                messageLabel.text = errorMessage
                messageLabel.textAlignment = .right
            }
            self.messageLabel.alpha = 1
            self.messageLabel.textColor = Constants.errorColor
            self.messageBottomConstraint.constant = 17
        }
    }
}
