//
//  Driver.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import Firebase
import Geofirestore
import CoreLocation

struct Driver {
    
    static let geoFirestoreRef = Firestore.firestore().collection(Driver.K.collection)
    static var geoFirestore: GeoFirestore { GeoFirestore(collectionRef: Driver.geoFirestoreRef) }
    
    struct K {
        
        static let collection = "driver-location"
        
        static let uid = "uid"
        static let location = "location"
    }
    
    let uid: String
    var location: CLLocation
    var fullName: String
    
    
    func getLocation(completion: @escaping(CLLocation?) -> Void ) {
        
        Driver.geoFirestore.getLocation(forDocumentWithID: uid) { (location: CLLocation?, error) in
            
            if let error = error {
                
                print("An error occurred: \(error)")
                completion(nil)
                
            } else if let location = location {
                
                print("Location: [\(location.coordinate.latitude), \(location.coordinate.longitude)]")
                completion(location)
                
            } else {
                
                print("GeoFirestore does not contain a location for this document")
                completion(nil)
                
            }
        }
        
    }
    
    func setLocation(origin: CLLocation) -> Void {
        
        Driver.geoFirestore.setLocation(location: origin, forDocumentWithID: uid) { error in
            
            if let error = error {
                
                print("An error occured: \(error)")
                
            } else {
                
                print("Saved location successfully!")
                
            }
        }
    }
 }
