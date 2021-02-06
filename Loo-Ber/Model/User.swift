//
//  User.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 3/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit

enum AccountType: Int {
    
    case passenger = 0
    case driver = 1
    
}

struct User {
    
    struct K {
        
        static let collection = "users"
        static let uid = "uid"
        static let fullName = "fullName"
        static let email = "email"
        static let accountType = "accountType"
        static let userDriverActive = "UserDriverActive"
    }
    
    var data: [String: Any] {
        
        get {
            var dict = [String: Any]()
            
            dict = [User.K.uid: uid, User.K.fullName: fullName, User.K.email: email, User.K.accountType: accountType.rawValue]
            
            if let homeAddress = homeAddress {
                
                dict[FavoriteLocationType.home.key] = homeAddress
                
            }
            
            if let workAddress = workAddress {
                
                dict[FavoriteLocationType.work.key] = workAddress
                
            }
            
            return dict
        }
        
        set {
            uid = newValue[User.K.uid] as? String ?? ""
            fullName = newValue[User.K.fullName] as? String ?? ""
            email = newValue[User.K.email] as? String ?? ""
        
            let rawValue = newValue[User.K.accountType] as? Int ?? 0
            accountType = AccountType(rawValue: rawValue) ?? .passenger
            
            
            if let homeAddress = newValue[FavoriteLocationType.home.key] as? String {
                
                self.homeAddress = homeAddress
                
            }
            
            if let workAddress = newValue[FavoriteLocationType.work.key] as? String {
                
                self.workAddress = workAddress
            }
        }
    }
    
    var uid: String = ""
    var fullName: String = ""
    var email: String = ""
    var accountType: AccountType = .passenger
    var homeAddress: String?
    var workAddress: String?
    
    var firstInitial: String { return String(fullName.prefix(1)) }
    
    var isActive: Bool {
        
        get {
            
            let defaults = UserDefaults.standard
            
            let key = "\(uid).\(K.userDriverActive)"
            
            if let _ = defaults.value(forKey: key) {
                
                return defaults.bool(forKey: key)
                
            } else {
                
                return true
                
            }
            
        }
        
        set {
            
            let defaults = UserDefaults.standard
            
            let key = "\(uid).\(K.userDriverActive)"
            
            defaults.set(newValue, forKey: key)
        }
        
    }
    
    var profileImage: UIImage {
        
        get {
            
            let image = UIImage.getProfileImage(uid: uid)
            
            if let pi = image {
                
                return pi
                
            } else {
                
                return UIImage()
                
            }
        }
        
        set {
            
            newValue.updateProfileImage(uid: uid)
            
        }
    }
}
