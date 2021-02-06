//
//  YourTripsController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit

class YourTripsController: UITableViewController {
    
    //MARK: - Properties
    private var trips = [Trip]()
    
    private let loadingView: UIView = {
        
        let view = UIView()
        
        view.backgroundColor = .white
        
        return view
        
    }()
    
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .lightGray
        label.text = "Loading trips..."
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.color = .black
        
        return indicator
        
    }()
    
    private let reuseIdentifier = "TripInfoCell"
    
    var user: User? {
        
        didSet {
            
            guard let safeUser = self.user else { return }
            
            
            Service.shared.getExtendedTrips(for: safeUser) { extendedTrips, error in
                
                if let error = error {
                    
                    print("DEBUG: YTC.user.didSet: getExtendedTrips are failed with error \(error)")
                    
                } else {
                    
                    self.trips = extendedTrips
                    
                    if extendedTrips.count == 0 {
                        
                        self.loadingIndicator.stopAnimating()
                        self.loadingIndicator.isHidden = true
                        self.loadingLabel.text = "No trips are found"
                        
                    } else {
                        
                        self.tableView.tableFooterView = UIView()
                        
                    }
                    
                    
                    self.tableView.reloadData()
                    
                }
            }
            
        }
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTebleView()
        
        configureNavigationBar()
        
    }
    //MARK: - Helpers
    
    func configureTebleView() {
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        
        loadingView.addSubview(loadingIndicator)
        loadingIndicator.centerX(inView: loadingView)
        loadingIndicator.centerY(inView: loadingView, constant: -100)
        
        loadingView.addSubview(loadingLabel)
        loadingLabel.centerX(inView: loadingView)
        loadingLabel.anchor(top: loadingIndicator.bottomAnchor, paddingTop: 32)
        
        loadingView.frame = view.frame
        
        loadingIndicator.startAnimating()
        
        tableView.tableFooterView = loadingView
        
        tableView.register(YourTripsViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        
    }
    
    func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = .backgroundColor
        navigationController?.navigationBar.backgroundColor = .backgroundColor
        
        navigationItem.title = "Your trips"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismissal))
    }
    
    
    //MARK: - Selectors
    
    @objc func handleDismissal() {
        print("DEBUG: YTC.handleDismissal")
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITableViewController Delegate / Datasource

extension YourTripsController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return trips.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! YourTripsViewCell
        
        let extendedTrip = trips[indexPath.row]
        
        cell.clear()
        cell.trip = extendedTrip
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return view.frame.width
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DEBUG: YTC.tableView.didSelectRowAt")
        
        let summaryController = TripSummaryController()
        
        let extendedTrip =  self.trips[indexPath.row]
        
        summaryController.modalPresentationStyle = .fullScreen
        
        self.present(summaryController, animated: true) {
            
            summaryController.extendedTrip = extendedTrip
            
        }
    }
}
