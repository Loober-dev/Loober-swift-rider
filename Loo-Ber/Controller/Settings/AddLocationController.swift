//
//  AddLocationController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/7/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import MapKit

private let reuseIdentifier = "AddLocationCell"

protocol AddLocationControllerDelagate: class {
    
    func update(address: String, for locationType: FavoriteLocationType)
    
}

class AddLocationController: UITableViewController {
    //MARK: - Properties
    
    weak var delegate: AddLocationControllerDelagate?
    
    private let searchBar = UISearchBar()
    private let seachCompliter = MKLocalSearchCompleter()
    private var searchResults = [MKLocalSearchCompletion]() {
        didSet {
            
            self.tableView.reloadData()
            
        }
    }
    private var locationType: FavoriteLocationType!
    /// Location Handler
    private let locationManager = LocationHandler.shared.locationManager
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableVew()
        configureSeachBar()
        configureSearchCompliter()
        configureNavigationBar()
    }
    
    init(locationType: FavoriteLocationType) {
        
        self.locationType = locationType
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Helpers
    
    func configureTableVew() {
        tableView.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 60
        
        tableView.addShadow()
    }
    
    func configureSeachBar() {
        searchBar.sizeToFit()
        searchBar.delegate = self
        navigationItem.titleView = searchBar
    }
    
    func configureSearchCompliter() {
        
        print("DEBUG: ALC.configureSearchCompliter")
        
        guard let location = locationManager?.location else { return }
        
        print("DEBUG: ALC.configureSearchCompliter: location: \(location)")
        print("DEBUG: ALC.configureSearchCompliter: locationType: \(String(describing: locationType))")
        
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        seachCompliter.region = region
        seachCompliter.delegate = self
        
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.prompt = locationType.subtitle
    }
    
    //MARK: - Selectors
    @objc func handleDismissal() {
        print("DEBUG: SC.handleDismissal")
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITableViewControllerDelegate/ DataSource

extension AddLocationController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        let result = searchResults[indexPath.row]
        
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        var address = result.title
        
        if result.subtitle != K.empty {
            address = address + " " + result.subtitle
        }
        
        delegate?.update(address: address, for: locationType)
        
        print("DEBUG: ALC.Update: address\(address)")
        
        dismiss(animated: true, completion: nil)
        
    }
}

//MARK: - UISerchBarDelegate

extension AddLocationController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        seachCompliter.queryFragment = searchText
        
    }
}

//MARK: - MKSearchCompliterDelegate

extension AddLocationController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        
        searchResults = completer.results
        
    }
}
