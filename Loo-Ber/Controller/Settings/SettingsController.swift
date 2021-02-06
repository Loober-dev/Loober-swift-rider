//
//  SettingsController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/6/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit

enum FavoriteLocationType: Int, CaseIterable, CustomStringConvertible {
    case home
    case work
    
    var description: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        }
    }
    
    var subtitle: String {
        switch self {
        case .home: return "Add Home address"
        case .work: return "Add Work address"
        }
    }
    
    var key: String {
        switch self {
        case .home: return "HomeAddress"
        case .work: return "WorkAddress"
        }
    }
}

private let reuseIdentifier = K.reuseIdentifier

//MARK: - SettingsControllerDelegate

protocol SettingsControllerDelegate: class {
    func favoriteAddressUpdated(for option: FavoriteLocationType, address: String )
}

class SettingsController: UITableViewController {
    
    //MARK: - Properties
    
    /// User Favorite locations
    private var favoriteLocations: [FavoriteLocationType: String] = {
        
        var dict = [FavoriteLocationType: String]()
        
        FavoriteLocationType.allCases.forEach { dict[$0] = $0.subtitle }
        
        return dict
    }()
    
    private var user: User? {
        
        didSet {
            
           if let homeAddress = user?.homeAddress {
                
                favoriteLocations[FavoriteLocationType.home] = homeAddress
                
            }
            
            if let workAddress = user?.workAddress {
                
                favoriteLocations[FavoriteLocationType.work] = workAddress
            }
            
        }
    }
    
    weak var delegate: SettingsControllerDelegate?
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        
        configureNavigationBar()
        
        
    }
    
    //MARK: - Selectors
    
    @objc func handleDismissal() {
        print("DEBUG: SC.handleDismissal")
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Helpers
    
    func set(user: User) { self.user = user }
    
    func configureTableView() {
        tableView.backgroundColor = .white
        tableView.rowHeight = 60
        tableView.register(LocationInputCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.tableFooterView = UIView()
        
        let userInfoHeader = UserInfoHeader(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        
        userInfoHeader.user = user
        tableView.tableHeaderView = userInfoHeader
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = .backgroundColor
        navigationController?.navigationBar.backgroundColor = .backgroundColor
        
        navigationItem.title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismissal))
    }
}

//MARK: - UITableViewDelegate / Datasource

extension SettingsController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteLocations.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16)
        title.textColor = .white
        title.text = "Favorites"
        view.addSubview(title)
        title.centerY(inView: view, left: view.leftAnchor, paddingLeft: 8)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationInputCell
        
        guard let option = FavoriteLocationType(rawValue: indexPath.row ) else { return cell }
        
        if let favoriteAddress = favoriteLocations[option] {
            
            cell.configureCell(title: option.description, address: favoriteAddress)
            
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let option = FavoriteLocationType(rawValue: indexPath.row ) else { return  }
        
        print("DEBUG: \(option.description)")
        
        let controller = AddLocationController(locationType: option)
        
        controller.delegate = self
        
        let nc = UINavigationController(rootViewController: controller)
        
        DispatchQueue.main.async {
            
            self.present(nc, animated: true, completion: nil)
            
        }
        
    }
    
}

extension SettingsController: AddLocationControllerDelagate {
    
    func update(address: String, for locationType: FavoriteLocationType) {
        print("DEBUG: SC.update: address: \(address) locationType: \(locationType)")
        
        if locationType == .home {
            
            user?.homeAddress = address
            
            favoriteLocations[.home] = address
            
        } else if locationType == .work {
            
            user?.workAddress = address
            
            favoriteLocations[.work] = address
            
        }
       
        if let user = self.user {
            
            Service.shared.updateUserData(for: user) { error in
                
                if let error = error {
                    
                    print("DEBUG: SC.update: Failed to update user: \(user) with error: \(error.localizedDescription)")
                    
                } else {
                    
                    print("DEBUG: SC.update: user: \(user) has been updated")
                    
                    self.delegate?.favoriteAddressUpdated(for: locationType, address: address)
                    
                    self.tableView.reloadData()
                }
            }
        }
    }
}
