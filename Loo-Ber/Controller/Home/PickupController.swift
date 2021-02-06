//
//  PickupController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 3/29/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import MapKit

class PickupController: UIViewController {
    
    //MARK: - Properties
    
    weak var delegate: PickupControllerDelegate?
    
    private let mapView = MKMapView()
    
    private lazy var circularProgressView: CircularProgressView = {
        
        let frame = CGRect(x: 0, y: 0, width: 360, height: 360)
        let progressView = CircularProgressView(frame: frame)
        
        progressView.addSubview(mapView)
        mapView.setDimension(height: 268, width: 268)
        mapView.layer.cornerRadius = 268/2
        mapView.centerX(inView: progressView)
        mapView.centerY(inView: progressView, constant: 32)
        
        return progressView
    }()
    
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        
        button.setImage(#imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    private let pickupLabel: UILabel = {
        let label = UILabel()
        label.text = "Would you like to pickup this passenger?"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        
        return label
        
    }()
    
    private let acceptTripButton: UIButton = {
        let button = UIButton(type: .system)
        
        button.backgroundColor = .white
        button.setTitle("ACCEPT TRIP", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.addTarget(self, action: #selector(acceptTripButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    let trip: Trip
    
    //MARK: - Lifecycle
    
    init(trip: Trip) {
        self.trip = trip
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("DEBUG: Pickup Controller for trip id \(trip.id)")
        
        configureUI()
        
        self.perform(#selector(animateProgress), with: nil, afterDelay: 0.8)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    //MARK: - Helpers
    func configureUI() {
        view.backgroundColor = .backgroundColor
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 16)
        
//        view.addSubview(mapView)
//        mapView.setDimension(height: 270, width: 270)
//        mapView.layer.cornerRadius = 270/2
//
//        mapView.centerX(inView: view)
//        mapView.centerY(inView: view, constant: -200)
        
        view.addSubview(circularProgressView)
        circularProgressView.setDimension(height: 360, width: 360)
        circularProgressView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        circularProgressView.centerX(inView: view)
        
        view.addSubview(pickupLabel)
        pickupLabel.centerX(inView: view)
        pickupLabel.anchor(top: circularProgressView.bottomAnchor, paddingTop: 16)
        
        view.addSubview(acceptTripButton)
        acceptTripButton.anchor(top: pickupLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 16, paddingLeft: 32, paddingRight: 32, height: 50)
        
        configureMapView()
        
    }
    
    func configureMapView() {
        let center = trip.pickupCoordinates.coordinate
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        mapView.setRegion(region, animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)
        
        mapView.selectAnnotation(annotation, animated: true)
    }
    
    //MARK: - Selectors
    
    @objc func cancelButtonPressed() {
        
        print("DEBUG: Cancel Button Pressed!")
        
        dismiss(animated: true, completion: nil)
        self.delegate?.tripIsRejected(trip: self.trip)
        
    }
    
    @objc func acceptTripButtonPressed() {
        
        print("DEBUG: Accept Trip Button Pressed")
        
        
        Service.shared.acceptTrip(trip: trip) { result, error in
            
            if let error = error {
                
                print("DEBUG: Update Transaction is failed with \(error.localizedDescription)")
                
            } else {
                
                print("DEBUG: Update Transaction successfuly complitted!")
                
                
                self.dismiss(animated: true, completion: nil)
                self.delegate?.tripIsAccepted(trip: self.trip)
                
            }
        }
    }
    
    @objc func animateProgress() {
        circularProgressView.animatePulsatingLayer()
        circularProgressView.setProgressWithAnimation(duration: 7, value: 0) {

            print("DEBUG: animateProgress.complited")
            self.dismiss(animated: true, completion: nil)
            
            
        }
    }
}

//MARK: - PickupController Delegate

protocol PickupControllerDelegate: class {
    func tripIsRejected(trip: Trip)
    func tripIsAccepted(trip: Trip)
}
