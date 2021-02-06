//
//  SignUpController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 1/30/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import Firebase
import Geofirestore

class SignUpController: UIViewController {
    
    //MARK: - Properties
    
    let db = Firestore.firestore()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Loober"
        label.font = UIFont(name: "Avenir-Light", size: 45)
        label.textColor = UIColor(white: 1, alpha: 1)
        return label
    }()
    
    private let developerCred: UILabel = {
        let label = UILabel()
        label.text = "Developed by Emmanuel Klutse"
        label.font = UIFont(name: "Avenir-Light", size: 12)
        label.textColor = UIColor(white: 1, alpha: 1)
        return label
    }()
    
     private lazy var emailContainerView: UIView = {
           let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailTextField)
           view.heightAnchor.constraint(equalToConstant: 50).isActive = true
           return view
       }()
    
    private lazy var fullNameContainerView: UIView = {
           
           let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_person_outline_white_2x"), textField: fullNameTextField)
           view.heightAnchor.constraint(equalToConstant: 50).isActive = true
           
           return view
    }()
    
    private lazy var passwordContainerView: UIView = {
        
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextFileld)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        return view
    }()
    
    private lazy var accountTypeContainerView: UIView = {
        
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_account_box_white_2x-1"), segmentedControl: accountTypeSegmentedControl)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        return view
    }()
    
    private let emailTextField: UITextField = {
    
        return UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)
        
    }()
    
    private let fullNameTextField: UITextField = {
    
        return UITextField().textField(withPlaceholder: "Full Name", isSecureTextEntry: false)
        
    }()
    
    private let passwordTextFileld: UITextField = {
        
        return UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)
        
    }()
    
    private let accountTypeSegmentedControl: UISegmentedControl = {
        
        let sc = UISegmentedControl(items: ["Rider", "Driver"])
        
        sc.backgroundColor = UIColor(white: 0.9, alpha: 0.3)
        sc.tintColor = UIColor(white: 1, alpha: 1)
        sc.selectedSegmentIndex = 0
        sc.setEnabled(false, forSegmentAt: 1)
        
        return sc
    }()
    
    private let signUpButton: AuthButton = {

        return AuthButton.createButton(title: "Sign Up")
        
    }()
    
    private let alreadyHaveAccountButton: UIButton = {
        
        return AuthButton.createAttributedButton(title: "Already have an account?  ", subTitle: "Log In", target: self, action: #selector(handleShowLogIn))
        
    }()
    
    // MARK: - Selectors
    
    @objc func handleShowLogIn() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleSignUp() {
        
        guard let email = emailTextField.text  else { return }
        guard let password = passwordTextFileld.text else { return }
        guard let fullName = fullNameTextField.text else { return }
       
        Auth.auth().createUser(withEmail: email, password: password) { (result , error) in
            
            if let error = error {
                print("Failed to register new user with error \(error)")
                self.presentAlertController(withMessage: "\(error.localizedDescription)")
                return
            }
            
            guard let uid = result?.user.uid else {
                
                fatalError("Could not get user ID")
                
            }
            
            let accountType = AccountType(rawValue: self.accountTypeSegmentedControl.selectedSegmentIndex) ?? .passenger
            
            let user = User(uid: uid, fullName: fullName, email: email, accountType: accountType)
            
            if accountType == .driver {
                
                let location = LocationHandler.shared.locationManager.location
                
                if let origin = location {
                    
                    let driver = Driver(uid: uid, location: origin, fullName: fullName)
                    
                    driver.setLocation(origin: origin)
                }
            }
            
            self.db.collection(User.K.collection).addDocument(data: user.data) { error in
                
                if let error = error {
                    print("DEBUG: Could not add new user with error \(error)")
                }
                else {
                    print("DEBUG: User is added")
                    
                    guard let controller = UIApplication.shared.keyWindow?.rootViewController as? ContainerController else { return }
                    controller.configure()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        hideKeyboard()
    }
    
    //MARK: - Helper functions
    
    
    func configureUI() {
        
        configureNavigationBar()
        
        view.backgroundColor = .backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        
        view.addSubview(developerCred)
               developerCred.anchor(top: titleLabel.bottomAnchor)
               developerCred.centerX(inView: view)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView, fullNameContainerView, passwordContainerView])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 24
        
        view.addSubview(stack)
        stack.anchor(top: developerCred.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(accountTypeContainerView)
        
        accountTypeContainerView.anchor(top: stack.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 25, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(signUpButton)
        
        signUpButton.anchor(top: accountTypeContainerView.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 25, paddingLeft: 16, paddingRight: 16)
        
        signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        
    
        view.addSubview(alreadyHaveAccountButton)
        alreadyHaveAccountButton.centerX(inView: view)
        alreadyHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
    
    func hideKeyboard(){
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
               tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}
