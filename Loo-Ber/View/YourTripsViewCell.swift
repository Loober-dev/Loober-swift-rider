//
//  YourTripsViewCell.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import MapKit

class YourTripsViewCell: UITableViewCell {
    
    //MARK: - Properties
    
    var trip: Trip? {
        
        didSet {
            
            if let tripRoute = trip?.route {
                
                //self.mapView.center(onTripRoute: tripRoute, fromDistance: 2)
                
                self.mapView.animate(tripRoute: tripRoute, duration: 1.5) {
                    
                    print("DEBUG: YTVC.trip.didSet: trip Animation is complited")
                    
                }
                
            }
            
            if let start = trip?.start {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
                
                dateLabel.text = dateFormatter.string(from: start)
                
            }
            
            if let distance = trip?.distance {
                
                distanceLabel.text = String(format: "%.2f km", distance / 1000)
                
            }
            
        }
        
    }
    
    private let mapView = MKMapView()
    
    private let distanceImageView: UIImageView = {
        
        let view = UIImageView()
        
        view.tintColor = .lightGray
        view.tag = 12
        
        if let image = UIImage(systemName: "map") {
            
            view.image = image
            
        }
        
        return view
        
    }()
    
    
    private let dateImageView: UIImageView = {
        
        let view = UIImageView()
        
        view.tintColor = .lightGray
        view.tag = 13
        
        if let image = UIImage(systemName: "calendar.circle") {
            
            view.image = image
            
        }
        
        return view
        
    }()
    
    private let arrowImageView: UIImageView = {
        
        let view = UIImageView()
        
        view.tintColor = .lightGray
        view.tag = 13
        
        if let image = UIImage(systemName: "arrow.right.circle") {
            
            view.image = image
            
        }
        
        return view
        
    }()
    
    private let infoView: UIView = {
        let view = UIView()
        
        view.backgroundColor = UIColor(white: 1, alpha: 0.75)
        
        return view
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = "20 km"
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = "04.04.2020"
        return label
    }()
    
    //MARK: - Helpers
    
    func configureMapView() {
        
        addSubview(mapView)
        
        // mapView.frame = frame
        
        mapView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 1, paddingLeft: 0, paddingBottom: 1, paddingRight: 0)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.isUserInteractionEnabled = false
        
        mapView.delegate = self
    }
    
    
    func configureDistanceImageView() {
        
        infoView.addSubview(distanceImageView)
        
        distanceImageView.setDimension(height: 32, width: 32)
        distanceImageView.centerY(inView: infoView)
        distanceImageView.centerX(inView: infoView, constant: 32)
        
        
        infoView.addSubview(distanceLabel)
        distanceLabel.centerY(inView: distanceImageView, left: distanceImageView.rightAnchor, paddingLeft: 10)
        
    }
    
    func configureDateImageView() {
        
        infoView.addSubview(dateImageView)
        dateImageView.setDimension(height: 34, width: 34)
        dateImageView.centerY(inView: infoView)
        dateImageView.anchor(left: infoView.leftAnchor, paddingLeft: 16)
        
        infoView.addSubview(dateLabel)
        dateLabel.centerY(inView: dateImageView, left: dateImageView.rightAnchor, paddingLeft: 10)
        
    }
    
    
    func configureArrowImageView() {
        
        infoView.addSubview(arrowImageView)
        arrowImageView.setDimension(height: 34, width: 34)
        arrowImageView.centerY(inView: infoView)
        arrowImageView.anchor(right: infoView.rightAnchor, paddingRight: 16)
        
        
    }
    func configureInfoView() {
        
        configureDistanceImageView()
        
        configureDateImageView()
        
        configureArrowImageView()
        
        addSubview(infoView)
        
        infoView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor,  paddingLeft: 0, paddingBottom: 1, paddingRight: 0, height: K.smallInfoViewHeight)
       
    }
    
    
    //MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        configureMapView()
        configureInfoView()
       
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func clear() {
         mapView.removeAllAnnotationsAndOverlays()
    }
    
    deinit {
        mapView.removeAllAnnotationsAndOverlays()
        mapView.delegate = nil
    }
    

}

//MARK: - MKMapViewDelegate

extension YourTripsViewCell: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        guard let polyline = overlay as? MKPolyline else {
            
            return MKOverlayRenderer()
            
        }
        
        let polylineRenderer = MKPolylineRenderer(overlay: polyline)
        polylineRenderer.strokeColor = .mainBlueTint
        polylineRenderer.lineWidth = 4
        return polylineRenderer
    }
    
    
}

