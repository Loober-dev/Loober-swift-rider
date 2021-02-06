//
//  Location.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase

struct Location {
    
    struct K {
        
        static let id = "id"
        static let uid = "uid"
        static let tripId = "tripId"
        static let passengerUid = "passengerUid"
        static let driverUid = "driverUid"
        static let status = "status"
        
        static let coordinates = "coordinates"
        static let altitude = "altitude"
        static let timestamp = "timestamp"
        static let speed = "speed"
        static let course = "course"
        static let message = "message"
        
        static let collection = "location-log"
        
    }
    
    var data: [String: Any] {
        
        get {
            
            var dict: [String: Any] = [
                Location.K.id: id,
                Location.K.uid: uid,
                Location.K.tripId: tripId,
                Location.K.passengerUid: passengerUid,
                Location.K.driverUid: driverUid,
                Location.K.status: status.rawValue,
                Location.K.coordinates: coordinates.data,
                Location.K.altitude: altitude,
                Location.K.timestamp: timestamp.timeIntervalSince1970,
                Location.K.speed: speed,
                Location.K.course: course
            ]
            
            if let message = self.message {
                
                dict[Location.K.message] = message
                
            }
            
            return dict
            
        }
        
        set {
            
            let rawStatus = newValue[Location.K.status] as? Int ?? 0
            let timeInterval = newValue[Location.K.timestamp] as? Double ?? 0
            
            id = newValue[Location.K.id] as? String ?? ""
            uid = newValue[Location.K.uid] as? String ?? ""
            tripId = newValue[Location.K.tripId] as? String ?? ""
            passengerUid = newValue[Location.K.passengerUid] as? String ?? ""
            driverUid = newValue[Location.K.driverUid] as? String ?? ""
            status = TripStatus(rawValue: rawStatus) ?? TripStatus.isRequested
            
            coordinates.data = newValue[Location.K.coordinates] as? [String: Any] ?? TripCoordinates.K.empty
            altitude = newValue[Location.K.altitude] as? Double ?? 0
            timestamp = Date(timeIntervalSince1970: timeInterval)
            speed = newValue[Location.K.speed] as? Double ?? 0
            course = newValue[Location.K.course] as? Double ?? 0
            
            if let message = newValue[Location.K.message] as? String {
                
                self.message = message
                
            }
            
        }
        
    }
    
    var id: String = String(Int.random(in: 0...1000000000))
    var uid: String = ""
    var tripId: String = ""
    var passengerUid: String = ""
    var driverUid: String = ""
    var status: TripStatus = TripStatus.isRequested
    
    var coordinates: TripCoordinates = TripCoordinates(latitude: 0, longitude: 0)
    var altitude: Double = 0
    var timestamp = Date()
    var speed: Double = 0
    var course: Double = 0
    var message: String?
    
    init(location: CLLocation, trip: Trip) {
        
        uid = Auth.auth().currentUser?.uid ?? ""
        
        tripId = trip.id
        passengerUid = trip.uid
        driverUid = trip.driverUid
        status = trip.status
        
        coordinates = TripCoordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        altitude = location.altitude
        timestamp = location.timestamp
        speed = location.speed
        course = location.course
    }
    
    init(trip: Trip, status: TripStatus) {
        
        uid = Auth.auth().currentUser?.uid ?? ""
        
        tripId = trip.id
        passengerUid = trip.uid
        driverUid = trip.driverUid
        self.status = status
        
    }
    
    init(trip: Trip) {
        
        uid = Auth.auth().currentUser?.uid ?? ""
        
        tripId = trip.id
        passengerUid = trip.uid
        driverUid = trip.driverUid
        self.status = trip.status
        
    }
    
    init(location: CLLocation) {
        
        uid = Auth.auth().currentUser?.uid ?? ""
        
        coordinates = TripCoordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        altitude = location.altitude
        timestamp = location.timestamp
        speed = location.speed
        course = location.course
        
    }
    
    init() {
        
        uid = Auth.auth().currentUser?.uid ?? ""
        
    }
    
    
}
