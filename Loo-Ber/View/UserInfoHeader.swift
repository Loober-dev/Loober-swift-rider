//
//  UserInfoHeader.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class UserInfoHeader: UIView {
    
    //MARK: - Properties
    
    var user: User? {
        
        didSet {
            fullnameLabel.text = user?.fullName
            emailLabel.text = Auth.auth().currentUser?.email
            
            profileImageView.image = user?.profileImage
            
        }
    }
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = false
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray
        
        return imageView
    }()
    
    private let fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = ""
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.text = ""
        return label
    }()
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        
        backgroundColor = .white
        
        addSubview(profileImageView)
        profileImageView.centerY(inView: self, left: leftAnchor, paddingLeft: 12)
        profileImageView.setDimension(height: 64, width: 64)
        profileImageView.layer.cornerRadius = 64/2
        
        let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
        
        addSubview(stack)
        
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.centerY(inView: profileImageView, left: profileImageView.rightAnchor, paddingLeft: 12)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
