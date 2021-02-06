//
//  LocationHandler.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 3/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import CoreLocation
import Geofirestore
import CoreLocation

enum RegionType {
    
    case pickup
    case destination
    
    var rid: String {
        
        switch self {
            
        case .pickup: return "PickUpRegion"
        case .destination: return "DestinationRegion"
            
        }
        
    }
}

class LocationHandler: NSObject, CLLocationManagerDelegate {
    
    /// Shared LocationHandler object
    static let shared = LocationHandler()
    /// Pickup Region radius in metters
    static let regionRadius: Double = 30
    /// Loaction Manager
    var locationManager: CLLocationManager!
    /// Current location
    var location: CLLocation?
    /// Location query
    var locationQuery: GFSCircleQuery?
    /// Observation radius in km
    var radius: Double = 30
    /// User account type
    var accountType: AccountType?
    /// Save updated locations to Geofirestore databse
    var updateGeofirestore: Bool = false
    /// Current user UID
    var uid: String?
    /// Last location
    var lastLocation: CLLocation?
    /// Delegate for Location Hangler
    var delegate: LocationHandlerDelegate?
    /// Region to to observe
    var region: CLCircularRegion?
    /// Trip object for logging process
    var trip: Trip?
    /// Trip status  fro logging process
    var status: TripStatus = .isRequested
    /// Logging active indicator
    var logging: Bool = false
    /// Last Logged Location
    var lastLoggedLocation: CLLocation?
    
    override init() {
        super.init()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
    }
    
    /**
     Enable Geofirestore Updates for account type and user id
     
     - Parameter accountType: account type for location apdates
     - Parameter uid: user id
     
     */
    func enableGeofirestoreUpdates(for accountType: AccountType, uid: String) {
        self.accountType = accountType
        self.updateGeofirestore = true
        self.uid = uid
    }
    
    /**
     Disable Geofirestore Updates for account type and user id
     
     */
    
    func disableGeofirestoreUpdates() {
        self.accountType = nil
        self.updateGeofirestore = false
        self.uid = nil
    }
    
    /**
     Enable location service for given account type
     
     - Parameter accountType: account type
     
     */
    
    func enableLocationSevices(for accountType: AccountType) {
        
        switch CLLocationManager.authorizationStatus() {
            
        case .notDetermined:
            print("DEBUG: LH.enableLocationSevices: not determined")
            locationManager.requestWhenInUseAuthorization()
            
        case .restricted, .denied:
            print("DEBUG: LH.enableLocationSevices: restricted or denied")
            
        case .authorizedAlways:
            print("DEBUG: LH.enableLocationSevices: authorized always")
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            location = locationManager.location
            
            if let center = location {
                
                setObservers(for: accountType, center: center, radius: radius)
                
            }
            
        case .authorizedWhenInUse:
            print("DEBUG:  LH.enableLocationSevices: authorized when in use")
            locationManager.requestAlwaysAuthorization()
            
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    
    func setObservers(for accountType: AccountType, center: CLLocation, radius: Double = 0.6) {
        
        removeAllObservers()

        if accountType == .passenger {
            
            locationQuery = Driver.geoFirestore.query(withCenter: center, radius: radius)
            
        } else {
            
            locationQuery = Trip.geoFirestore.query(withCenter: center, radius: radius)
        }
        
        
        print("DEBUG: LH.setObservers: A/C Type: \(accountType), location: \(center) and radius: \(radius) km")
        
        if let query = locationQuery {
            
            
            let _ = query.observe(.documentEntered, with: { key, location in
                self.delegate?.documentEntered(for: accountType, key: key, location: location)
            })
            
            let _ = query.observe(.documentExited, with: { key, location in
                self.delegate?.documentExited(for: accountType, key: key, location: location)
            })
            
            let _ = query.observe(.documentMoved, with: { key, location in
                self.delegate?.documentMoved(for: accountType, key: key, location: location)
            })
            
        }
        
    }
    
    /**
     
     Remove All Observers
     
     */
    func removeAllObservers() {
        
        print("DEBUG: LH.removeAllObservers")
        
        locationQuery?.removeAllObservers()
        
    }
    
    /**
     
     Find placemark for given location
     
     - Parameter location: location to translate
     - Parameter completion: compleation handler with placemark as input parameter
     
     */
    func lookUpLocation(_ location: CLLocation, completion: @escaping (CLPlacemark?) -> Void ) {
        
        
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if error == nil {
                
                let firstLocation = placemarks?[0]
                completion(firstLocation)
                
            }
            else {
                
                completion(nil)
                
            }
        })
        
    }

    /**
     
     Get placemark for the given address
     
     - Parameter address: address string to convert to coordinates
     - Parameter completion: completion handler with the address placemark or error
     
     */
    func getPlacemark(for address: String, completion: @escaping(CLPlacemark?, NSError?) -> Void ) {
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            
            if error == nil {
                
                if let placemark = placemarks?[0] {
                        
                    completion(placemark, nil)
                    return
                }
                
            }
                
            completion(nil, error as NSError?)
        }
    }
    
    /**
    
    Update Driver location in Geofirestore
    
    - Parameter uid: driver uid
    - Parameter location: new driver location
    
    */
    func updateDriverLocation(uid: String, location: CLLocation) {
        
        Driver.geoFirestore.setLocation(location: location, forDocumentWithID: uid) { error in
            
            if let error = error {
                
                print("DEBUG: LH.updateDriverLocation: Failed to store location with error: \(error.localizedDescription)")
                
            } else {
                
                self.lastLocation = location
                self.delegate?.driverLocationUpdatedToNew(location: location)
            }
        }
    }
    
    /**
     
     Update Passenger location in Geofirestore
     
     - Parameter uid: passenger uid
     - Parameter location: new passenger location
     
     */
    func updatePassengerLocation(uid: String, location: CLLocation) {
        
        Trip.geoFirestore.setLocation(location: location, forDocumentWithID: uid) { error in
            
            if let error = error {
                
                print("DEBUG: LH.updatePassengerLocation: Failed to store location with error: \(error.localizedDescription)")
                
            } else {
                
                self.lastLocation = location
                self.delegate?.passengerLocationUpdatedToNew(location: location)
                
            }
        }
    }
    
    func adjustLocationQuery(for location: CLLocation) {
        
        print("DEBUG: LM.adjustLocationQuery")
        
        if let center = self.locationQuery?.center {
            
            if location.distance(from: center) > self.radius * 100 {
                
                print("DEBUG: LM.adjustLocationQuery: location: \(location)")
                
                self.locationQuery?.center = location
                
            }
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if !updateGeofirestore {
            
            if let location = locations.last {
                
                if let lastLocation = self.lastLocation {
                    
                    if lastLocation.distance(from: location) < 30 {
                        
                        return
                        
                    }
                }
                
                self.lastLocation = location
                
                self.adjustLocationQuery(for: location)
                
                self.log(location: location, message: nil)
                
                delegate?.userLocationUpdated(location: location)
                
            }
            
            return
            
        }
        
        if let uid = self.uid, let accountType = self.accountType, let location = locations.last {
            
            if let lastLocation = self.lastLocation {
                
                if lastLocation.distance(from: location) < 30 {
                    
                    return
                    
                }
            }
            
            self.log(location: location, message: nil)
            
            if accountType == .driver {
                
                self.adjustLocationQuery(for: location)
                
                self.updateDriverLocation(uid: uid, location: location)
                
            } else {
                
                self.adjustLocationQuery(for: location)
                
                self.updatePassengerLocation(uid: uid, location: location)
                
            }
        }
    }
    
    /**
     
     Filter trips based on radus from the current driver location
     
     - Parameter trips: trip array to filter
     - Parameter by: radius from current location
     
     */
    
    func filter(trips: [Trip], by radius: Double) -> [Trip] {
        
        guard let driverCoordinate = locationManager?.location?.coordinate else { return [Trip]() }
        
        let driverLocation = CLLocation(latitude: driverCoordinate.latitude, longitude: driverCoordinate.longitude)
        
        return trips.filter { trip in
            
            let passengerCoordinate = trip.pickupCoordinates
            let passengerLocation = CLLocation(latitude: passengerCoordinate.latitude, longitude: passengerCoordinate.longitude)
            
            let distance = driverLocation.distance(from: passengerLocation)
            
            return distance < radius
            
        }
    }
    
    /**
     Set Custom Region for pickup location
     
     - Parameter coordinates: pickup location coordinates
     - Returns: True if region is setted up and location manager is start monitoring. False if current location already in the region
     
     */
    
    func setCustomRegion(withCoordinates coordinates: CLLocationCoordinate2D, type: RegionType? = .pickup) -> Bool {
        
        region = CLCircularRegion(center: coordinates, radius: LocationHandler.regionRadius, identifier: type?.rid ?? RegionType.pickup.rid)
        
        if let region = region {
            
            /*
             
             Need to check if our location already in the region. It looks like if it's true we don't get event from location manager. Let's generate our event in this case
             
             */
            
            if let location = locationManager.location  {
                
                let target = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                
                if location.distance(from: target) < LocationHandler.regionRadius {
                    
                    delegate?.didEnterRegion(region)
                    
                    return false
                    
                }
                
            }
            
            locationManager.startMonitoring(for: region)
            
            print("DEBUG: LH.setCustomRegion: Location manager start monitoring region: \(region)")
            
            return true
        }
        
        return false
    }
    
    /**
     
     Stop region monitoring
     
     */
    func stopRegionMonitoring() {
        
        if let region = region {
            
            locationManager.stopMonitoring(for: region)
            
            print("DEBUG: LH.stopRegionMonitoring: region: \(region)")
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        print("DEBUG: LH.locationManager did enter region \(region)")
        
        delegate?.didEnterRegion(region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        print("DEBUG: LH.locationManager did exit region \(region)")
        
        delegate?.didExitRegion(region)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
        print("DEBUG: LH.locationManager did start monitorin region \(region)")
        
    }
}

//MARK: - LocationHandler protocol

protocol LocationHandlerDelegate: class {
    
    /**
     Geofirestore document entered in the  specified region
     
     - Parameter accountType: type of the account for the document
     - Parameter key: document id
     - Parameter location: document geo-location
     
     */
    func documentEntered(for accountType: AccountType, key: String?, location: CLLocation?)
    
    /**
    Geofirestore document exit the specified region
    
    - Parameter accountType: type of the account for the document
    - Parameter key: document id
    - Parameter location: document geo-location
    
    */
    func documentExited(for accountType: AccountType, key: String?, location: CLLocation?)
    
    /**
    Geofirestore document moved in the specified region
    
    - Parameter accountType: type of the account for the document
    - Parameter key: document id
    - Parameter location: document geo-location
    
    */
    func documentMoved(for accountType: AccountType, key: String?, location: CLLocation?)
    
    /**
     Geofirestore drivel location  updated event handler
     
     - Parameter locatation: new driver location
     
     */
    func driverLocationUpdatedToNew(location: CLLocation)
    
    /**
    Geofirestore passenger location  updated event handler
    
    - Parameter locatation: new driver location
    
    */
    func passengerLocationUpdatedToNew(location: CLLocation)
    
    /**
     
     User has been entered in the region
     
     - Parameter region: specified region
     
     */
    func didEnterRegion(_ region: CLRegion)
    
    /**
    
    User has been exited  the region
    
    - Parameter region: specified region
    
    */
    func didExitRegion(_ region: CLRegion)
    
    /**
     
     User location update - called if Geofirestore update is disabled
     
     - Parameter locatation: new user location
     
     */
    func userLocationUpdated(location: CLLocation)
    
}

extension LocationHandlerDelegate {
    
    func didEnterRegion(_ region: CLRegion) { print("DEBUG: LH.didEnterRegion: \(region) ") }
    
    func didExitRegion(_ region: CLRegion) { print("DEBUG: LH.didExitRegion: \(region) ") }
    
    func userLocationUpdated(location: CLLocation) { print("DEBUG: LH.userLocationUpdated: \(location) ") }
    
}


extension LocationHandler {
    
    func loggingStart(trip: Trip, status: TripStatus) {
        
        if self.logging { return }
        
        print("DEBUG: LH.loggingStart: trip: \(trip), status: \(status)")
        
        self.trip = trip
        self.status = status
        self.logging = true
        
    }
    
    func loggingStop() {
        
        print("DEBUG: LH.loggingStop")
        
        self.trip = nil
        self.status = .isRequested
        self.logging = false
        
    }
    
    func log(location: CLLocation, message: String?) {
    
        if !logging { return }
        
        guard let trip = self.trip else { return }
        
        print("DEBUG: LH.log(location:, message:)")
        
        if let lastLocation = lastLoggedLocation {
            
            if lastLocation.distance(from: location) < 30 {
                
                return
                
            }
            
        }
        
        var logEntry = Location(location: location, trip: trip)
        
        logEntry.status = self.status
        
        if let message = message {
            
            logEntry.message = message
            
        }
        
        print("DEBUG: LH.log: location: \(location), status: \(self.status)")
        
        Service.shared.save(location: logEntry) { error in
            
            if let error = error {
                
                print("DEBUG: LH.log: logging error: \(error.localizedDescription)")
                
            } else {
                
                self.lastLoggedLocation = location
                
            }
        }
        
        
    }
    
    func log(status: TripStatus, message: String?) {
        
        print("DEBUG: LH.log(status:, message:)")
        
        if let location = locationManager.location {
            
            print("DEBUG: LH.log: location: \(location), status: \(status)")
            
            self.status = status
            
            guard let trip = self.trip else { return }
            
            var logEntry = Location(location: location, trip: trip)
            
            logEntry.status = status
            
            if let message = message {
                
                logEntry.message = message
                
            }
            
            Service.shared.save(location: logEntry) { error in
                
                if let error = error {
                    
                    print("DEBUG: LH.log: logging error: \(error.localizedDescription)")
                    
                } else {
                    
                    self.lastLoggedLocation = location
                    
                }
            }
           
        }
    }
    
    
}
