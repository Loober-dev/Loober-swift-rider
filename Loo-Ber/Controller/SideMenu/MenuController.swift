//
//  MenuController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/6/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit

enum MenuOptions: Int, CaseIterable, CustomStringConvertible {
    case yourTrip
    case settings
    case deleteUser
    case logout
    
    var description: String {
        switch self {
        case .yourTrip: return "Your Trips"
        case .settings: return "Settings"
        case .deleteUser: return "Delete User"
        case .logout: return "Log Out"
        }
    }
}

protocol MenuControllerDelegate: class {
    func didMenuOptionSelected(option: MenuOptions)
    func didSetActive(to active: Bool)
}

class MenuController: UITableViewController, UINavigationControllerDelegate {
    
    //MARK: - Properties
    
    let defaults = UserDefaults.standard
    
    let imagePicker = UIImagePickerController()
    
    weak var delegate: MenuControllerDelegate?
    
    private let reuseIdentifier = "MenuCell"
    
    private lazy var menuHeader: MenuHeader = {
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 140)
        
        let view = MenuHeader(frame: frame)
        
        return view
    }()
    
    var user: User?
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        
        view.backgroundColor = .white
        configureTebleView()
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    
    //MARK: - Selectors
    
    //MARK: - Helpers
    
    func configureTebleView() {
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 60
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        menuHeader.delegate = self
        
        tableView.tableHeaderView = menuHeader
    }
    
    func set(user: User) {
        
        self.user = user
        
        menuHeader.user = user
        
    }
    
    func driverStatusIsChanged(busy: Bool) {
        
        menuHeader.enableActivation(!busy)
        
    }
    
}

//MARK: - UITableViewDelagate/DataSource

extension MenuController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        MenuOptions.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        guard let option = MenuOptions(rawValue: indexPath.row ) else { return cell }
        
        cell.textLabel?.text = option.description
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let option = MenuOptions(rawValue: indexPath.row ) else { return }
        
        delegate?.didMenuOptionSelected(option: option)
        
    }
}

//MARK: - MenuHeaderDelegate

extension MenuController: MenuHeaderDelegate {
    
    func changeActive(to active: Bool) {
        
        print("DEBUG: MC.changeActive: active is \(active)")
        
        user?.isActive = active
        
        delegate?.didSetActive(to: active)
        
    }
    
    
    func changeImageTapped(_ view: MenuHeader) {
        
        print("DEBUG: MC.changeImageTapped")
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    
}

//MARK: - UIImagePickerControllerDelegate

extension MenuController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            fatalError("DEBUG: MC.imagePickerController: Could not get original image from Info dictionary")
        }
        

        if let menuHeader = self.tableView.tableHeaderView as? MenuHeader {
            
            user?.profileImage = image
            
            menuHeader.user = user
                
            
        }
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
}
