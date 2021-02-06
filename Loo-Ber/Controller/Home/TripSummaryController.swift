//
//  TripSummaryController.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import MapKit

class TripSummaryController: UIViewController {
    
    //MARK: - Properties
    
    private let Information: [Int:String] = [
        10: "Average trip speed",
        11: "Trip duration",
        12: "Trip distance",
        13: "Trip start date and time",
        14: "Passenger name",
        15: "Driver name"
    ]
    
    private var showInfo: Bool = false
    
    private var showInfoTag: Int = 0
    
    private let mapView = MKMapView()
    
    private var outgoingMessageLayer: CAShapeLayer!
    
    var extendedTrip: Trip? {
        
        didSet {
            
            if let passenger = extendedTrip?.passenger {
                
                passengerLabel.text = passenger.fullName
                
            }
            
            if let driver = extendedTrip?.driver {
                
                driverLabel.text = driver.fullName
                
            }
            
            if let speed = extendedTrip?.speed {
                
                speedLabel.text = String(format: "%.2f km/h", speed)
                
            }
            
            if let start = extendedTrip?.start, let end = extendedTrip?.end {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
                
                dateLabel.text = dateFormatter.string(from: start)
                
                let duration = end.timeIntervalSince1970 - start.timeIntervalSince1970
                
                timeLabel.text = String(format: "%.0f h %.0f m", duration / 3600, duration / 60)
                
            }
            
            if let distance = extendedTrip?.distance {
                
                distanceLabel.text = String(format: "%.2f km", distance / 1000)
                
            }
            
            showExtendedTrip()
            
        }
    }
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        
        button.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    private let speedImageView: UIImageView = {
        
        let view = UIImageView()
        
        view.tintColor = .lightGray
        view.tag = 10
        
        if let image = UIImage(systemName: "speedometer") {
            
            view.image = image
            
        }
        
        
        return view
        
    }()
    
    private let timeImageView: UIImageView = {
        
        let view = UIImageView()
        
        view.tintColor = .lightGray
        view.tag = 11
        
        if let image = UIImage(systemName: "stopwatch") {
            
            view.image = image
            
        }
        
        return view
        
    }()
    
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
    
    private let passengerImageView: UIImageView = {
        
        let view = UIImageView()
        
        view.tintColor = .lightGray
        view.tag = 14
        
        if let image = UIImage(systemName: "person.circle") {
            
            view.image = image
            
        }
        
        return view
        
    }()
    
    private let driverImageView: UIImageView = {
        
        let view = UIImageView()
        
        view.tintColor = .lightGray
        view.tag = 15
        
        if let image = UIImage(systemName: "car") {
            
            view.image = image
            
        }
        
        return view
        
    }()
    
    private let infoImageView: [UIImageView] = {
        
        return [
            {
                let view = UIImageView()
                
                view.tintColor = .lightGray
                
                if let image = UIImage(systemName: "info.circle") {
                    
                    view.image = image
                    
                }
                
                return view
            }(),
            {
                let view = UIImageView()
                
                view.tintColor = .lightGray
                
                if let image = UIImage(systemName: "info.circle") {
                    
                    view.image = image
                    
                }
                
                return view
            }(),
            {
                let view = UIImageView()
                
                view.tintColor = .lightGray
                
                if let image = UIImage(systemName: "info.circle") {
                    
                    view.image = image
                    
                }
                
                return view
            }(),
            {
                let view = UIImageView()
                
                view.tintColor = .lightGray
                
                if let image = UIImage(systemName: "info.circle") {
                    
                    view.image = image
                    
                }
                
                return view
            }(),
            {
                let view = UIImageView()
                
                view.tintColor = .lightGray
                
                if let image = UIImage(systemName: "info.circle") {
                    
                    view.image = image
                    
                }
                
                return view
            }(),
            {
                let view = UIImageView()
                
                view.tintColor = .lightGray
                
                if let image = UIImage(systemName: "info.circle") {
                    
                    view.image = image
                    
                }
                
                return view
            }()
        ]
        
    }()
    
    private let speedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = "65 km/h"
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = "0.5 h"
        return label
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
    
    private let passengerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = "Emmanuel Klutse"
        return label
    }()
    
    private let driverLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        label.text = "Bruce Wayne"
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        
        return label
    }()
    
    private let infoView: UIView = {
        let view = UIView()
        
        view.backgroundColor = UIColor(white: 1, alpha: 0.75)
        
        return view
    }()
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMapView()
        configureCancelButton()
        configureInfoView()
        
        // showTrip()
        
    }
    
    
    //MARK: - Helpers
    
    
    func showTrip() {
        
        Service.shared.fetchTripData(for: "7857815") { trip in
            
            Service.shared.extendTripByLogEntries(trip, for: .driver) { extendedTrip, error in
                
                if let error = error {
                    
                    print("DEBUG: TSC.viewDidLoad: \(error)")
                    
                } else {
                    
                    self.extendedTrip = extendedTrip
                    
                    self.showExtendedTrip()
                    
                }
                
            }
            
        }
        
    }
    
    func showExtendedTrip() {
        
        if let tripRoute = extendedTrip?.route {
            
            self.mapView.center(onTripRoute: tripRoute, fromDistance: 5)
            
            self.mapView.animate(tripRoute: tripRoute, duration: 2.5) {
                
                print("DEBUG: TSC.viewDidLoad: trip Animation is complited")
                
                self.toggleInfoView(show: true)
                
            }
        }
    }
    
    
    func configureMapView() {
        
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        mapView.delegate = self
        
    }
    
    func configureCancelButton() {
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 16)
    }
    
    func configureSpeedImageView() {
        
        infoView.addSubview(speedImageView)
        
        speedImageView.setDimension(height: 32, width: 32)
        speedImageView.anchor(top: infoView.topAnchor, left: infoView.leftAnchor, paddingTop: 32, paddingLeft: 16)
        
        
        infoView.addSubview(infoImageView[0])
        infoImageView[0].setDimension(height: 12, width: 12)
        infoImageView[0].anchor(top: speedImageView.bottomAnchor, left: speedImageView.rightAnchor, paddingTop: -5, paddingLeft: -5)
        
        infoView.addSubview(speedLabel)
        speedLabel.centerY(inView: speedImageView, left: speedImageView.rightAnchor, paddingLeft: 16)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(infoViewTapped(tapGestureRecognizer:)))
        
        speedImageView.isUserInteractionEnabled = true
        speedImageView.addGestureRecognizer(tap)
        
        
    }
    
    func configureTimeImageView() {
        
        infoView.addSubview(timeImageView)
        
        timeImageView.setDimension(height: 32, width: 32)
        timeImageView.anchor(top: speedImageView.bottomAnchor, left: infoView.leftAnchor, paddingTop: 32, paddingLeft: 16)
        
        infoView.addSubview(infoImageView[1])
        infoImageView[1].setDimension(height: 12, width: 12)
        infoImageView[1].anchor(top: timeImageView.bottomAnchor, left: timeImageView.rightAnchor, paddingTop: -5, paddingLeft: -5)
        
        infoView.addSubview(timeLabel)
        timeLabel.centerY(inView: timeImageView, left: timeImageView.rightAnchor, paddingLeft: 16)
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(infoViewTapped(tapGestureRecognizer:)))
        
        timeImageView.isUserInteractionEnabled = true
        timeImageView.addGestureRecognizer(tap)
        
    }
    
    func configureDistanceImageView() {
        infoView.addSubview(distanceImageView)
        
        distanceImageView.setDimension(height: 32, width: 32)
        distanceImageView.anchor(top: timeImageView.bottomAnchor, left: infoView.leftAnchor, paddingTop: 32, paddingLeft: 16)
        
        infoView.addSubview(infoImageView[2])
        infoImageView[2].setDimension(height: 12, width: 12)
        infoImageView[2].anchor(top: distanceImageView.bottomAnchor, left: distanceImageView.rightAnchor, paddingTop: -5, paddingLeft: -5)
        
        infoView.addSubview(distanceLabel)
        distanceLabel.centerY(inView: distanceImageView, left: distanceImageView.rightAnchor, paddingLeft: 16)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(infoViewTapped(tapGestureRecognizer:)))
        
        distanceImageView.isUserInteractionEnabled = true
        distanceImageView.addGestureRecognizer(tap)
    }
    
    func configureDateImageView() {
        
        infoView.addSubview(dateImageView)
        dateImageView.setDimension(height: 34, width: 34)
        dateImageView.centerX(inView: infoView)
        dateImageView.centerY(inView: speedImageView)
        
        infoView.addSubview(infoImageView[3])
        infoImageView[3].setDimension(height: 12, width: 12)
        infoImageView[3].anchor(top: dateImageView.bottomAnchor, left: dateImageView.rightAnchor, paddingTop: -5, paddingLeft: -5)
        
        infoView.addSubview(dateLabel)
        dateLabel.centerY(inView: dateImageView, left: dateImageView.rightAnchor, paddingLeft: 16)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(infoViewTapped(tapGestureRecognizer:)))
        
        dateImageView.isUserInteractionEnabled = true
        dateImageView.addGestureRecognizer(tap)
        
    }
    
    func configurePassengerImageView() {
        
        infoView.addSubview(passengerImageView)
        passengerImageView.setDimension(height: 34, width: 34)
        passengerImageView.centerX(inView: infoView)
        passengerImageView.centerY(inView: timeImageView)
        
        infoView.addSubview(infoImageView[4])
        infoImageView[4].setDimension(height: 12, width: 12)
        infoImageView[4].anchor(top: passengerImageView.bottomAnchor, left: passengerImageView.rightAnchor, paddingTop: -5, paddingLeft: -5)
        
        infoView.addSubview(passengerLabel)
        passengerLabel.centerY(inView: passengerImageView, left: passengerImageView.rightAnchor, paddingLeft: 16)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(infoViewTapped(tapGestureRecognizer:)))
        
        passengerImageView.isUserInteractionEnabled = true
        passengerImageView.addGestureRecognizer(tap)
    }
    
    func configureDriverImageView() {
        
        infoView.addSubview(driverImageView)
        driverImageView.setDimension(height: 34, width: 34)
        driverImageView.centerX(inView: infoView)
        driverImageView.centerY(inView: distanceImageView)
        
        infoView.addSubview(infoImageView[5])
        infoImageView[5].setDimension(height: 12, width: 12)
        infoImageView[5].anchor(top: driverImageView.bottomAnchor, left: driverImageView.rightAnchor, paddingTop: -5, paddingLeft: -5)
        
        infoView.addSubview(driverLabel)
        driverLabel.centerY(inView: driverImageView, left: driverImageView.rightAnchor, paddingLeft: 16)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(infoViewTapped(tapGestureRecognizer:)))
        
        driverImageView.isUserInteractionEnabled = true
        driverImageView.addGestureRecognizer(tap)
    }
    
    func configureInfoView() {
        
        infoView.layer.cornerRadius = 20
        
        configureSpeedImageView()
        
        configureTimeImageView()
        
        configureDistanceImageView()
        
        configureDateImageView()
        
        configurePassengerImageView()
        
        configureDriverImageView()
    
        
        infoView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: K.infoViewHeight)
        view.addSubview(infoView)
        
       
        
    }
    
    func toggleInfoView(show: Bool) {
        
        print("DEBUG: TSC.toggleInfoView: show \(true)")
        
        if self.infoView.frame.origin.y == self.view.frame.height - (show ? K.infoViewHeight : 0) {

            return

        }
        
        
        UIView.animate(withDuration: 0.3) {
            
            self.infoView.frame.origin.y = self.view.frame.height - (show ? K.infoViewHeight : 0)
            
        }
    }
    
    func showInfoMessage(text: String, center: CGPoint? = nil, right: Bool? = true) {
        
        infoLabel.text = text
        
        let constraintRect = CGSize(width: 0.66 * infoView.frame.width,
                                    height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: infoLabel.font as Any],
                                            context: nil)
        infoLabel.frame.size = CGSize(width: ceil(boundingBox.width),
                                  height: ceil(boundingBox.height))
        
        let bubbleSize = CGSize(width: infoLabel.frame.width + 28,
                                     height: infoLabel.frame.height + 20)
        
        let width = bubbleSize.width
        let height = bubbleSize.height
        
        let bezierPath = UIBezierPath()
        
        if right ?? true {
            
            bezierPath.move(to: CGPoint(x: width - 22, y: height))
            bezierPath.addLine(to: CGPoint(x: 17, y: height))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height - 17), controlPoint1: CGPoint(x: 7.61, y: height), controlPoint2: CGPoint(x: 0, y: height - 7.61))
            bezierPath.addLine(to: CGPoint(x: 0, y: 17))
            bezierPath.addCurve(to: CGPoint(x: 17, y: 0), controlPoint1: CGPoint(x: 0, y: 7.61), controlPoint2: CGPoint(x: 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: width - 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: width - 4, y: 17), controlPoint1: CGPoint(x: width - 11.61, y: 0), controlPoint2: CGPoint(x: width - 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: width - 4, y: height - 11))
            bezierPath.addCurve(to: CGPoint(x: width, y: height), controlPoint1: CGPoint(x: width - 4, y: height - 1), controlPoint2: CGPoint(x: width, y: height))
            bezierPath.addLine(to: CGPoint(x: width + 0.05, y: height - 0.01))
            bezierPath.addCurve(to: CGPoint(x: width - 11.04, y: height - 4.04), controlPoint1: CGPoint(x: width - 4.07, y: height + 0.43), controlPoint2: CGPoint(x: width - 8.16, y: height - 1.06))
            bezierPath.addCurve(to: CGPoint(x: width - 22, y: height), controlPoint1: CGPoint(x: width - 16, y: height), controlPoint2: CGPoint(x: width - 19, y: height))
            bezierPath.close()
            
        } else {
            
            bezierPath.move(to: CGPoint(x: 22, y: height))
            bezierPath.addLine(to: CGPoint(x: width - 17, y: height))
            bezierPath.addCurve(to: CGPoint(x: width, y: height - 17), controlPoint1: CGPoint(x: width - 7.61, y: height), controlPoint2: CGPoint(x: width, y: height - 7.61))
            bezierPath.addLine(to: CGPoint(x: width, y: 17))
            bezierPath.addCurve(to: CGPoint(x: width - 17, y: 0), controlPoint1: CGPoint(x: width, y: 7.61), controlPoint2: CGPoint(x: width - 7.61, y: 0))
            bezierPath.addLine(to: CGPoint(x: 21, y: 0))
            bezierPath.addCurve(to: CGPoint(x: 4, y: 17), controlPoint1: CGPoint(x: 11.61, y: 0), controlPoint2: CGPoint(x: 4, y: 7.61))
            bezierPath.addLine(to: CGPoint(x: 4, y: height - 11))
            bezierPath.addCurve(to: CGPoint(x: 0, y: height), controlPoint1: CGPoint(x: 4, y: height - 1), controlPoint2: CGPoint(x: 0, y: height))
            bezierPath.addLine(to: CGPoint(x: -0.05, y: height - 0.01))
            bezierPath.addCurve(to: CGPoint(x: 11.04, y: height - 4.04), controlPoint1: CGPoint(x: 4.07, y: height + 0.43), controlPoint2: CGPoint(x: 8.16, y: height - 1.06))
            bezierPath.addCurve(to: CGPoint(x: 22, y: height), controlPoint1: CGPoint(x: 16, y: height), controlPoint2: CGPoint(x: 19, y: height))
            bezierPath.close()
            
        }
        
        
        outgoingMessageLayer = CAShapeLayer()
        outgoingMessageLayer.path = bezierPath.cgPath
        outgoingMessageLayer.frame = CGRect(x: ( center?.x ?? infoView.frame.width/2 ) - width/2,
                                            y: ( center?.y ?? infoView.frame.height/2 ) - height/2,
                                            width: width,
                                            height: height)
        outgoingMessageLayer.fillColor = UIColor(red: 0.09, green: 0.54, blue: 1, alpha: 1).cgColor
        
        infoView.layer.addSublayer(outgoingMessageLayer)
        
        infoLabel.center = center ?? infoView.center
        infoView.addSubview(infoLabel)
    }
    
    func hideOutgoingMessage() {
        infoLabel.removeFromSuperview()
        outgoingMessageLayer.removeFromSuperlayer()
    }
    
    
    //MARK: - Selectors
    
    @objc func cancelButtonPressed() {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    @objc func infoViewTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        
        if let tappedImage = tapGestureRecognizer.view as? UIImageView {
            
            let tag = tappedImage.tag
            
            var y: CGFloat = 10
            var x: CGFloat = infoView.frame.width / 2
            var r: Bool = true
            let message: String = Information[tag] ?? "No info"
            let len: CGFloat = CGFloat(message.count)
            
            if tag > 12 {
                
                y = CGFloat((tag - 13) * 70)
                x = x - 70 - (len - 14)
                r = true
                
            } else {
                
                y = CGFloat((tag - 10) * 70)
                x = x - 100 + (len - 12)
                r = false
                
            }
            
            let center = CGPoint(x: x, y: y)
            
            
            if showInfo {
                
                hideOutgoingMessage()
                
                if showInfoTag == tappedImage.tag {
                    
                    showInfo.toggle()
                    showInfoTag = 0
                    
                } else {
                    
                    showInfoTag = tappedImage.tag
                    showInfoMessage(text: message, center: center, right: r)
                }
                
                
            } else {
                
                showInfo.toggle()
                showInfoTag = tappedImage.tag
                showInfoMessage(text: message, center: center, right: r)
                
                
            }
            
            
        }
        
        
    }
    
}

//MARK: - MKMapViewDelegate

extension TripSummaryController: MKMapViewDelegate {
    
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
