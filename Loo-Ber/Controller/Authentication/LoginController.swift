//
//  LoginController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 1/29/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class LoginController: UIViewController {
    
    // MARK: - Properties
    
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
    
    private lazy var passwordContainerView: UIView = {
        let view = UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordTextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    
    private let emailTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)
    }()
    
    private let passwordTextField: UITextField = {
        return UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)
    }()
    
    private let loginButton: AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()
    
    private let tougalooImage: UIImageView = {
        let view = UIImageView()
        view.image = #imageLiteral(resourceName: "tougaloo_png")
        return view
        }()
    
    let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account? ", attributes:
            [NSMutableAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint]))
        
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        return button
    }()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        hideKeyboard()
    }
    
    // MARK: - Selectors
    
    @objc func handleShowSignUp() {
        let signUp = SignUpController()
        
        navigationController?.pushViewController(signUp, animated: true)
    }
    
    @objc func handleLogin() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if let error = error {
                print("DEBUG: Login error \(error.localizedDescription)")
                self.presentAlertController(withMessage: "\(error.localizedDescription)")
            } else {
                print("DEBUG: Successuful logged in")
                
                DispatchQueue.main.async {
                    
                    let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                    
                    if let containerController = keyWindow?.rootViewController as? ContainerController {
                        
                        containerController.configure()
                        
                    }
                    
                    self.dismiss(animated: true, completion: nil)
                    
                }
            }
            
        }
    }
    
    // MARK: - Helper Functions
    
    func configureUI(){
        configureNavigationBar()
        
        view.backgroundColor = .backgroundColor
        
        view.addSubview(titleLabel)
        titleLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        
        view.addSubview(developerCred)
        developerCred.anchor(top: titleLabel.bottomAnchor)
        developerCred.centerX(inView: view)
        
        let stack = UIStackView(arrangedSubviews: [emailContainerView, passwordContainerView, loginButton])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 24
        
        view.addSubview(stack)
        stack.anchor(top: developerCred.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 40, paddingLeft: 16, paddingRight: 16)
        
        view.addSubview(tougalooImage)
        tougalooImage.anchor(top: loginButton.bottomAnchor, paddingTop: 40)
        tougalooImage.centerX(inView: view)
        
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 45)
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

