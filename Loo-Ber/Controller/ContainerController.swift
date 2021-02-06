//
//  ContainerController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/6/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import Firebase

class ContainerController: UIViewController {
    
    //MARK: - Properties
    private let homeController = HomeController()
    private let menuController = MenuController()
    private var user: User?
    
    private let blackView = UIView()
    
    private var shouldExpend = false
    
    override var prefersStatusBarHidden: Bool {
        return shouldExpend
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        view.backgroundColor = .backgroundColor
        //
        configureHomeController()
        configureMenuController()
        //
        configureBlackView()
        hideKeyboard()

        menuController.delegate = self
    }
    
    //MARK: - Selectors
    
    @objc func blackViewIsTapped() {
        shouldExpend = false
        animateMenu(shouldExpend: shouldExpend)
    }
    
    // MARK: - API
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            presentLoginController()
        } else {
            configure()
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            presentLoginController()
        } catch {
            print("DEBUG: Error signing out")
        }
    }
    
    //MARK: - Helper Functions
    
    func hideKeyboard(){
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
               tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func presentLoginController() {
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
             
            if let containerController = keyWindow?.rootViewController as? ContainerController {
            containerController.configure()
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /// Black View Configuration function
    func configureBlackView() {
        self.blackView.frame = CGRect(x: self.view.frame.width - 80, y: 0, width: 80, height: self.view.frame.height)
        blackView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        blackView.alpha = 0
        
        view.addSubview(blackView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(blackViewIsTapped))
        blackView.addGestureRecognizer(tap)
    }
    
    /**
     
     Logout the current user
     
     */
    func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("DEBUG: CC.logOut: Could not logout!")
        }
    }
    
    /**
    
    Delete the current user
    
    */
    func deleteUser() {
        
        let user = self.user
        
        Service.shared.deleteUserData(for: user!) { (error) in
                if let error = error {
                    print("Error deleting user \(error)")
                }
            }
        
        print("DEBUG: User \(user?.uid) is going to get deleted")
    }
    
    /// Configure Home Controller
    func configureHomeController() {
        
        print("DEBUG: CC.configureHomeController")
        
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)
        
        homeController.delegate = self
    }
    
    /// Configure Menu Controller
    func configureMenuController() {
        
        print("DEBUG: CC.configureMenuConroller ")
        
        addChild(menuController)
            menuController.didMove(toParent: self)
            menuController.view.frame = CGRect(x: 0, y: 40, width: self.view.frame.width, height: self.view.frame.height - 40)
            view.insertSubview(menuController.view, at: 0)
    }
    
    func set(user: User) {
        
        menuController.set(user: user)
        
        self.user = user
        
    }
    
    func configure() {
        
        homeController.configure()
        
    }
    
    /// Show / Hide Menu controlle
    func animateMenu(shouldExpend: Bool, completion: ((Bool) -> Void)? = nil) {
        
        let originX = self.view.frame.width - 80
        if shouldExpend {
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = originX
                
                
            }, completion: { _ in
                
                UIView.animate(withDuration: 0.2, animations: {
                     self.blackView.alpha = 1
                     
                }) { _ in
                    self.animateStatusBar()
                    
                    completion?(true)
                }
                
                
            })
            
        } else {
            
            self.blackView.alpha = 0
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = 0
                
                self.animateStatusBar()
                
            }, completion: completion)
            
        }
        
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)
    }
    
    func setFavoriteLocation(for option: FavoriteLocationType, address: String) {
        
        print("DEBUG: CC.setFavoriteLocation: for: \(option), address \(address)")
        
        homeController.setFavoriteLocation(for: option, address: address)
        
    }
    
}

//MARK: - MenuControllerDelegate

extension ContainerController: MenuControllerDelegate {
    
    func didSetActive(to active: Bool) {
        
        print("DEBUG: CC.didSetActive: active: \(active)")
        
        homeController.setActive(to: active)
        
    }
    
    
    func didMenuOptionSelected(option: MenuOptions) {
        print("DEBUG: \(option.description)")
        
        shouldExpend.toggle()
        animateMenu(shouldExpend: shouldExpend) { _ in
            
            switch option {
                
            case .yourTrip:
                
                let tripsController = YourTripsController()
                let nc = UINavigationController(rootViewController: tripsController)
                
                DispatchQueue.main.async {
                    
                    nc.modalPresentationStyle = .fullScreen
                    self.present(nc, animated: true) {
                        
                        tripsController.user = self.user
                        
                    }
                    
                }
                
            case .settings:
                
                let settingsController = SettingsController()
                
                settingsController.delegate = self
                
                if let user = self.user {
                    
                     settingsController.set(user: user)
                    
                }
               
                let nc = UINavigationController(rootViewController: settingsController)
                
                DispatchQueue.main.async {
                    
                    nc.modalPresentationStyle = .fullScreen
                    self.present(nc, animated: true, completion: nil)
                    
                }
                
            case .deleteUser:
                
                let alert = UIAlertController(title: nil, message: "Are you sure you want to delete this user?", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                    
                    self.deleteUser()
                    self.logOut()
                    self.homeController.presentLoginSignUp()
                }))
                               
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
                
            case .logout:
        
                let alert = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Log Out?", style: .destructive, handler: { _ in
                    self.logOut()
                    self.homeController.presentLoginSignUp()
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
}

//MARK: - HomeControllerDelegate

extension ContainerController: HomeControllerDelegate {
    
    func driverStatusIsChanged(busy: Bool) {
        
        menuController.driverStatusIsChanged(busy: busy)
        
    }
    
    
    func handleMenuToggle(with option: MenuOptions?) {
        
        print("DEBUG: CC.handleMenuToggle")
        shouldExpend.toggle()
        
        
        if let option = option {
            
            animateMenu(shouldExpend: shouldExpend) { _ in
                
                self.didMenuOptionSelected(option: option)
            }
            
        } else {
            
            animateMenu(shouldExpend: shouldExpend)
            
        }
    }
    
}

// MARK: - SettingsControllerDelegate

extension ContainerController: SettingsControllerDelegate {
    func favoriteAddressUpdated(for option: FavoriteLocationType, address: String) {
        
        print("DEBUG: CC.favoriteAddressUpdated: for: \(option), address \(address)")
        
        setFavoriteLocation(for: option, address: address)
    }
}
