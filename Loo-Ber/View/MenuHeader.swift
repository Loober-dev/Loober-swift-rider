//
//  MenuHeader.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import UIKit
import Firebase

protocol MenuHeaderDelegate: class {
    
    func changeImageTapped(_ view: MenuHeader)
    
    func changeActive(to active: Bool)
    
}

class MenuHeader: UIView {
    
    //MARK: - Properties
    
    var user: User? {
        
        didSet {
            
            fullnameLabel.text = user?.fullName
            emailLabel.text = Auth.auth().currentUser?.email
            
            if let accountType = user?.accountType {
                
                activeSwitch.isHidden = accountType == .passenger
                
            }
            
            if let image = user?.profileImage {
                
                profileImageView.image = image
                
            }
            
            activeSwitch.setOn(user?.isActive ?? true, animated: false)
            
        }
    }
    
    weak var delegate: MenuHeaderDelegate?
    
    private lazy var changeImageButton: UIButton = {
        let button = UIButton()
        
        button.addTarget(self, action: #selector(profileImageTapped), for: .touchUpInside)
        return button
    }()
    
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
        label.textColor = .white
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
    
    private let activeSwitch: UISwitch = {
        let control = UISwitch()
        control.onTintColor = .mainBlueTint
        control.addTarget(self, action: #selector(toggleActive), for: .valueChanged)
        return control
    }()
    
    //MARK: - Helpers
    
    func enableActivation(_ enable: Bool) {
        
        activeSwitch.isEnabled = enable
        
    }
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .backgroundColor
        
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor,  paddingTop: 4, paddingLeft: 12,  width: 64, height: 64)
        profileImageView.layer.cornerRadius = 64/2
        
        
        addSubview(changeImageButton)
        changeImageButton.setDimension(height: 64, width: 64)
        changeImageButton.anchor(top: topAnchor, left: leftAnchor,  paddingTop: 4, paddingLeft: 12,  width: 64, height: 64)
        changeImageButton.layer.cornerRadius = 64/2
        
        let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
        
        addSubview(stack)
        
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.centerY(inView: profileImageView, left: profileImageView.rightAnchor, paddingLeft: 12)
        
        addSubview(activeSwitch)
        activeSwitch.anchor(top: profileImageView.bottomAnchor, paddingTop: 20)
        activeSwitch.centerX(inView: profileImageView)
        activeSwitch.setOn(true, animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    @objc func profileImageTapped() {
        print("DEBUG: MenuHeader.profileImageTapped")
        delegate?.changeImageTapped(self)
    }
    
    @objc func toggleActive() {
        print("DEBUG: MenuHeader.toggleActive")
        
        delegate?.changeActive(to: activeSwitch.isOn)
    }
}
