//
//  Extensions.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 1/30/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import MapKit

extension UIColor {
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor.init(red: red/255, green: green/255, blue: blue/255, alpha: 1.0)
    }
    
    static let backgroundColor = UIColor.rgb(red: 0, green: 72, blue: 135)
    static let mainBlueTint = UIColor.rgb(red: 17, green: 154, blue: 237)
    static let outlineStrokeColor = UIColor.rgb(red: 234, green: 46, blue: 111)
    static let trackStrokeColor = UIColor.rgb(red: 56, green: 25, blue: 49)
    static let pulsatingFillColor = UIColor.rgb(red: 86, green: 30, blue: 63)
    
}

extension UIView {
    
    func inputContainerView(image: UIImage, textField: UITextField? = nil, segmentedControl: UISegmentedControl? = nil) -> UIView {
        
        let view = UIView()
        
        let imageView = UIImageView()
        imageView.image = image
        imageView.alpha = 0.87
        
        view.addSubview(imageView)
        
        
        if let textField = textField {
            
            imageView.centerY(inView: view)
            imageView.anchor(left: view.leftAnchor, paddingLeft: 8, width: 24, height: 24)
            
            view.addSubview(textField)
            textField.centerY(inView: view)
            textField.anchor(left: imageView.rightAnchor, bottom: view.bottomAnchor,
                             right: view.rightAnchor, paddingLeft: 8, paddingBottom: 8)
        }
        
        if let sc = segmentedControl {
            imageView.anchor(top: view.topAnchor, left: view.leftAnchor,
                             paddingTop: -8, paddingLeft: 8, width: 24, height: 24)
            
            view.addSubview(sc)
            sc.anchor(left: view.leftAnchor, right: view.rightAnchor,
                    paddingLeft: 8, paddingRight: 8)
            sc.centerY(inView: view, constant: 8)
        }
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        view.addSubview(separatorView)
        separatorView.anchor(left: view.leftAnchor, bottom: view.bottomAnchor,
                             right: view.rightAnchor, paddingLeft: 8, height: 0.75)
        
        return view
    }
    
    func anchor( top: NSLayoutYAxisAnchor? = nil,
                left: NSLayoutXAxisAnchor? = nil,
                bottom: NSLayoutYAxisAnchor? = nil,
                right: NSLayoutXAxisAnchor? = nil,
                paddingTop: CGFloat = 0.0,
                paddingLeft: CGFloat = 0.0,
                paddingBottom: CGFloat = 0.0,
                paddingRight: CGFloat = 0.0,
                width: CGFloat? = nil,
                height: CGFloat? = nil) {
        
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        
        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if let height = height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    func centerX(inView view: UIView, constant: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        
        centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: constant).isActive = true
    }
    
    func centerY(inView view: UIView, left: NSLayoutXAxisAnchor? = nil, paddingLeft: CGFloat = 0, constant: CGFloat = 0) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true
        
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
    }
    
    func setDimension(height: CGFloat, width: CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        heightAnchor.constraint(equalToConstant: height).isActive = true
        widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    
    func addShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.55
        layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        layer.masksToBounds = false
    }
}

extension UITextField {
    func textField(withPlaceholder placeholder: String, isSecureTextEntry: Bool) -> UITextField {
        let tf = UITextField()
        
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 16)
        tf.textColor = .white
        tf.keyboardAppearance = .dark
        tf.isSecureTextEntry = isSecureTextEntry
        tf.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.lightGray])
        
        return tf
    }
    
}

//MARK: - MKPlaceMark Extension

extension MKPlacemark {
    
    var address: String {
        
        if let subThoroughfare = subThoroughfare {
            
            if let thoroughfare = thoroughfare {
                
                return "\(subThoroughfare) \(thoroughfare), \(locality ?? " "), \(administrativeArea ?? " ")"
                
            } else {
                
                return "\(subThoroughfare), \(locality ?? " "), \(administrativeArea ?? " ")"
                
            }
            
        } else {
            
            if let thoroughfare = thoroughfare {
                
                return "\(thoroughfare), \(locality ?? " "), \(administrativeArea ?? " ")"
                
            } else {
                
                return "\(locality ?? " "), \(administrativeArea ?? " ")"
                
            }
            
        }
    }
}

//MARK: - MKMapView Extension

extension MKMapView {
    
    func zoomToFit(annotations: [MKAnnotation]) {
        var zoomRect = MKMapRect.null
        
        annotations.forEach { ann in
            let annotationPoint = MKMapPoint(ann.coordinate)
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.01, height: 0.01)
            
            zoomRect = zoomRect.union(pointRect)
        }
        
        let insets = UIEdgeInsets(top: 75, left: 75, bottom: 300, right: 75)
        setVisibleMapRect(zoomRect, edgePadding: insets, animated: true)
    }
    
    func removeAnnotationAndOverlay(annotation: MKAnnotation) {
        
        removeAnnotation(annotation)
        
        if overlays.count > 0 {
            
            if let overlay = overlays.first {
                
                removeOverlay(overlay)
                
            }
            
        }
       
    }
    
    func removeAllOverlays() {
        
        if overlays.count > 0 {
            
            removeOverlays(overlays)
                
        }
        
    }
    
    func removeAllDriverAnnotations() {
        
        if let _ = annotations.first(where: { $0 is DriverAnnotation }) {
            
            removeAnnotations(annotations.filter { $0 is DriverAnnotation } )
            
        }
        
    }
    
    func removeAllAnnotations() {
        
        if annotations.count > 0 {
            
            removeAnnotations(annotations)
            
        }
    }
    
    func removeAllAnnotationsAndOverlays() {
        
        removeAllOverlays()
        
        removeAllAnnotations()
    }
    
    
    func center(onRoute route: [CLLocationCoordinate2D], fromDistance km: Double) {
        
        let center = MKPolyline(coordinates: route, count: route.count).coordinate
        
        setCamera(MKMapCamera(lookingAtCenter: center, fromDistance: km * 1000, pitch: 0, heading: 0), animated: false)
    }
    
    func animate(route: [CLLocationCoordinate2D], duration: TimeInterval, completion: (() -> Void)?) {
        
        guard route.count > 0 else { return }
        
        guard duration > 0 else {
            
            let finalPolyline = MKPolyline(coordinates: route, count: route.count)
            
            self.addOverlay(finalPolyline)
            
            let start = MKPointAnnotation()
            start.coordinate = route.first!
            
            let end = MKPointAnnotation()
            end.coordinate = route.last!
            
            self.addAnnotations([start, end])
            
            completion?()
            
            return
        }
        
        var currentStep = 1
        let totalSteps = route.count
        let stepDrawDuration = duration/TimeInterval(totalSteps)
        var previousSegment: MKPolyline?
        
        let start = MKPointAnnotation()
        start.coordinate = route.first!
        start.title = "Trip Start"
        
        self.addAnnotation(start)
        
        let _ = Timer.scheduledTimer(withTimeInterval: stepDrawDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                
                timer.invalidate()
                
                completion?()
                
                return
            }
            
            if let previous = previousSegment {
                
                self.removeOverlay(previous)
                
                previousSegment = nil
            }
            
            guard currentStep < totalSteps else {
               
                let finalPolyline = MKPolyline(coordinates: route, count: route.count)
                
                self.addOverlay(finalPolyline)
                
                let end = MKPointAnnotation()
                end.coordinate = route.last!
                end.title = "Trip End"
                
                self.addAnnotation(end)
                
                timer.invalidate()
                
                completion?()
                
                return
            }
            
        
            let subCoordinates = Array(route.prefix(upTo: currentStep))
            let currentSegment = MKPolyline(coordinates: subCoordinates, count: subCoordinates.count)
            self.addOverlay(currentSegment)
            
            previousSegment = currentSegment
            currentStep += 1
        }
    }
    
    func center(onTripRoute tripRoute: [TripCoordinates], fromDistance km: Double) {
        
        let route = tripRoute.map { entry -> CLLocationCoordinate2D in
            
            return entry.coordinate
            
        }
        
        let center = MKPolyline(coordinates: route, count: route.count).coordinate
        
        setCamera(MKMapCamera(lookingAtCenter: center, fromDistance: km * 1000, pitch: 0, heading: 0), animated: false)
    }
    
    
    
    func animate(tripRoute: [TripCoordinates], duration: TimeInterval, completion: (() -> Void)?) {
        
        guard tripRoute.count > 0 else { return }
        
        let route = tripRoute.map { entry -> CLLocationCoordinate2D in
            
            return entry.coordinate
            
        }
        
        if tripRoute.count == 1 {
            
        
            let start = MKPointAnnotation()
            start.coordinate = route.first!
            start.title = "Trip Start"
            
            if let description = tripRoute.first!.description {
                
                start.title = description
                
            }
            
            self.addAnnotation(start)
                       
            completion?()
            
            return
        }
        
        guard duration > 0 else {
            
            let finalPolyline = MKPolyline(coordinates: route, count: route.count)
            
            self.addOverlay(finalPolyline)
            
            let start = MKPointAnnotation()
            start.coordinate = route.first!
            start.title = "Trip Start"
            
            if let description = tripRoute.first!.description {
                
                start.title = description
                
            }
            
            let end = MKPointAnnotation()
            end.coordinate = route.last!
            end.title = "Trip End"
            
            if let description = tripRoute.last!.description {
                
                end.title = description
                
            }
            
            self.addAnnotations([start, end])
            
            completion?()
            
            return
        }
        
        var currentStep = 1
        let totalSteps = route.count
        let stepDrawDuration = duration/TimeInterval(totalSteps)
        

        let start = MKPointAnnotation()
        start.coordinate = route.first!
        start.title = "Trip Start"
        
        if let description = tripRoute.first!.description {
            
            start.title = description
            
        }
        
        self.addAnnotation(start)
        
        let _ = Timer.scheduledTimer(withTimeInterval: stepDrawDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                
                timer.invalidate()
                
                completion?()
                
                return
            }
            
            
            guard currentStep < totalSteps else {
               
                let finalPolyline = MKPolyline(coordinates: route, count: route.count)
                
                self.addOverlay(finalPolyline)
                
                let end = MKPointAnnotation()
                end.coordinate = route.last!
                end.title = "Trip End"
                
                if let description = tripRoute.last!.description {
                    
                    end.title = description
                    
                }
                
                self.addAnnotation(end)
                
                timer.invalidate()
                
                completion?()
                
                return
            }
            
            if let description = tripRoute[currentStep].description {
                
                let point = MKPointAnnotation()
                point.coordinate = tripRoute[currentStep].coordinate
                
                point.title = description
                
                self.addAnnotation(point)
                
            }
        
            let subCoordinates = [route[currentStep-1], route[currentStep]]
            let currentSegment = MKPolyline(coordinates: subCoordinates, count: subCoordinates.count)
            self.addOverlay(currentSegment)
            
            currentStep += 1
        }
    }
}


//MARK: - UIVewController Extension

extension UIViewController {
    
    static let loadingViewTag  = 8799
    
    func shouldPresentLoadingView(_ present: Bool, message: String? = nil) {
        
        if present {
            
            DispatchQueue.main.async {
                
                print("DEBUG: Presenting Loading View...")
                
                let loadingView = UIView()
                loadingView.frame = self.view.frame
                loadingView.backgroundColor = .black
                loadingView.alpha = 0
                loadingView.tag = UIViewController.loadingViewTag
                
                let indicator = UIActivityIndicatorView()
                indicator.style = .large
                indicator.color = .white
                indicator.center = self.view.center
                
                let label = UILabel()
                label.text = message
                label.font = UIFont.systemFont(ofSize: 20)
                label.textColor = .white
                label.textAlignment = .center
                label.alpha = 0.87
                
                self.view.addSubview(loadingView)
                loadingView.addSubview(indicator)
                loadingView.addSubview(label)
                
                label.centerX(inView: self.view)
                label.anchor(top: indicator.bottomAnchor, paddingTop: 32)
                
                indicator.startAnimating()
                
                UIView.animate(withDuration: 0.3) {
                    
                    loadingView.alpha = 0.7
                    
                }
            }
            
            
        } else {
            
            
            DispatchQueue.main.async {
                
                print("DEBUG: Dismissing loading view....")
                
                self.view.subviews.forEach { subview in
                    
                    if subview.tag == UIViewController.loadingViewTag {
                        UIView.animate(withDuration: 0.3, animations: {
                            subview.alpha = 1
                        }) { _ in
                            subview.removeFromSuperview()
                        }
                    }
                }
                
            }
            
        }
        
    }
    
    func presentAlertController(withMessage message: String, and title: String? = nil) {
        
        let alertController = UIAlertController(title: title ?? "Error" , message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
        
    }

}

extension CLLocationCoordinate2D {
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }

    func getBearing(point : CLLocationCoordinate2D) -> Double {

        let lat1 = degreesToRadians(degrees: self.latitude)
        let lon1 = degreesToRadians(degrees: self.longitude)

        let lat2 = degreesToRadians(degrees: point.latitude)
        let lon2 = degreesToRadians(degrees: point.longitude)

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let radiansBearing = atan2(y, x)

        return radiansToDegrees(radians: radiansBearing)
    }
    
    func distance(from: CLLocationCoordinate2D) -> Double {
        
        if self.longitude == 0 && self.longitude == 0 { return 0 }
        if from.longitude == 0 && from.longitude == 0 { return 0 }
        
        let locationTo = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let locationFrom = CLLocation(latitude: from.latitude, longitude: from.longitude)
        
        return locationTo.distance(from: locationFrom)
    }
}

extension UIImage {
    
    func imageToFile(fileName: String) {
        
     guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = self.jpegData(compressionQuality: 1) else { return }

        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
                
                print("DEBUG: UIImage.save: Removed old image")
                
            } catch let removeError {
                
                print("DEBUG: UIImage.save: couldn't remove file at path", removeError)
                
            }

        }

        do {
            
            try data.write(to: fileURL)
            
            print("DEBUG: UIImage.save: fileURL: \(fileURL)")
            
        } catch let error {
            
            print("DEBUG: UIImage.save: error saving file with error", error)
            
        }

    }


    static func imageFromFile(fileName: String) -> UIImage? {

      let documentDirectory = FileManager.SearchPathDirectory.documentDirectory

        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)

        if let dirPath = paths.first {
            
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            
            print("DEBUG: UIImage.imageFromFile: imageUrl: \(imageUrl)")
            
            let image = UIImage(contentsOfFile: imageUrl.path)
            
            return image

        }

        return nil
    }
    
    static func getProfileImage(uid: String) -> UIImage? {
        
        let defaults = UserDefaults.standard
        
        if let imageFile = defaults.string(forKey: "\(uid).\(K.userProfileImage)") {
            
            if let image = UIImage.imageFromFile(fileName: imageFile) {
                
               return image
                
            }
        }
        
        return nil
        
    }
    
    func updateProfileImage(uid: String) {
        
        let defaults = UserDefaults.standard
        
        let fileName = "\(uid).\(K.userProfileImageFile)"
        
        self.imageToFile(fileName: fileName)
        
        defaults.set(fileName, forKey: "\(uid).\(K.userProfileImage)")
        
    }
}



