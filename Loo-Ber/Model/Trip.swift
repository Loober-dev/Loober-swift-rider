//
//  Trip.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 3/28/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase
import Geofirestore

enum TripStatus: Int {
    
    case isRequested = 0
    case isAccepted  = 1
    case inProgress  = 2
    case isCompleted = 3
    case isCanceled  = 4
    
}

struct TripCoordinates {
    
    struct K {
        
        static let latitude = "latitude"
        static let longitude = "longitude"
        
        static let empty = [TripCoordinates.K.latitude: 0, TripCoordinates.K.longitude: 0]
    }
    
    var latitude: Double = 0
    var longitude: Double = 0
    var description: String?
    
    var coordinate: CLLocationCoordinate2D {
        
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
    }
    
    var location: CLLocation {
        
        CLLocation(latitude: latitude, longitude: longitude)
        
    }
    
    var data: [String: Any] {
        
        get {
            return [TripCoordinates.K.latitude: latitude, TripCoordinates.K.longitude: longitude]
        }
        
        set {
            latitude = newValue[TripCoordinates.K.latitude] as? Double ?? 0
            longitude = newValue[TripCoordinates.K.longitude] as? Double ?? 0
        }
    }
    
    init(coordinates: CLLocationCoordinate2D) {
        
        self.latitude = coordinates.latitude
        self.longitude = coordinates.longitude
        
    }
    
    init(latitude: Double, longitude: Double) {
        
        self.latitude = latitude
        self.longitude = longitude
        
    }
    
    init() {
        self.latitude = 0
        self.longitude = 0
    }
    
    func distance(from: TripCoordinates) -> Double {
        
        if self.longitude == 0 && self.latitude == 0 { return 0 }
        if from.longitude == 0 && from.latitude == 0 { return 0 }
        
        return self.location.distance(from: from.location)
    }
}

struct Trip {
    
    static let geoFirestoreRef = Firestore.firestore().collection(Trip.K.geoCollection)
    static var geoFirestore: GeoFirestore { GeoFirestore(collectionRef: Trip.geoFirestoreRef) }
    
    struct K {
        static let collection = "trips"
        static let geoCollection = "pickup-location"
        
        static let id = "id"
        static let uid = "uid"
        static let destinationCoordinates = "destinationCoordinates"
        static let pickupCoordinates = "pickupCoordinates"
        static let status = "status"
        static let driverUid = "driverUid"
    }
    
    var data: [String: Any] {
        
        get {
            return [
                Trip.K.id: id,
                Trip.K.uid: uid,
                Trip.K.destinationCoordinates: destinationCoordinates.data,
                Trip.K.pickupCoordinates: pickupCoordinates.data,
                Trip.K.status: status.rawValue,
                Trip.K.driverUid: driverUid
            ]
        }
        
        set {
            let rawStatus = newValue[Trip.K.status] as? Int ?? 0
            
            id = newValue[Trip.K.id] as? String ?? ""
            
            uid = newValue[Trip.K.uid] as? String ?? ""
            
            destinationCoordinates.data = newValue[Trip.K.destinationCoordinates] as? [String: Any] ?? TripCoordinates.K.empty
            
            pickupCoordinates.data = newValue[Trip.K.pickupCoordinates] as? [String: Any] ?? TripCoordinates.K.empty
            
            status = TripStatus(rawValue: rawStatus) ?? TripStatus.inProgress
            
            driverUid = newValue[Trip.K.driverUid] as? String ?? ""
            
        }
    }
    
    var id: String = String(Int.random(in: 0...10000000))
    var uid: String = ""
    var destinationCoordinates: TripCoordinates = TripCoordinates(latitude: 0, longitude: 0)
    var pickupCoordinates: TripCoordinates = TripCoordinates(latitude: 0, longitude: 0)
    var status: TripStatus = TripStatus.isRequested
    var driverUid: String = ""
    var log: [Location]?
    var route: [TripCoordinates]?
    var start: Date?
    var end: Date?
    var distance: Double?
    var speed: Double?
    var driver: User?
    var passenger: User?
    
    init(destinationCoordinates: CLLocationCoordinate2D, pickupCoordinates: CLLocationCoordinate2D) {
        
        uid = Auth.auth().currentUser?.uid ?? ""
        driverUid = ""
        status = .isRequested
        
        self.destinationCoordinates = TripCoordinates(coordinates: destinationCoordinates)
        self.pickupCoordinates = TripCoordinates(coordinates: pickupCoordinates)
    }
    
    init() {
        destinationCoordinates = TripCoordinates()
        pickupCoordinates = TripCoordinates()
    }
    
    func setPickupLocation() {
        
        let origin = pickupCoordinates.location
        
        Trip.geoFirestore.setLocation(location: origin, forDocumentWithID: id) { error in
            
            if let error = error {
                
                print("DEBUG: failed to save pickup location with: \(error.localizedDescription)")
                
            } else {
                
                print("DEBUG: Saved pickup location successfully!")
                
            }
        }
    }
    
    func removePickupLocation() {
        
        Trip.geoFirestore.removeLocation(forDocumentWithID: id) { error in
            
            if let error = error {
                
                print("DEBUG: failed to remove pickup location with: \(error.localizedDescription)")
                
            } else {
                
                print("DEBUG: Remove location successfully!")
                
            }
        }
    }
    
}
