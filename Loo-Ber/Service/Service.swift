//
//  Service.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 3/24/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

struct Service {
    
    let containerController = ContainerController()
    let homeController = HomeController()
    let uiViewController = UIViewController()
    
    static var shared = Service()
    
    let db = Firestore.firestore()
    
    func fetchUserData(for userId: String? = nil, completion: @escaping(User) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        print("DEBUG: Service.fetchUserData: userId: \(userId ?? uid)")
        
        let predicate = NSPredicate(format: "\(User.K.uid) = %@", userId ?? uid)
        
        db.collection(User.K.collection).filter(using: predicate).getDocuments { querySnapshot, error in
            if let error = error {
                
                print("DEBUG: Service.fetchUserData: failed to fetch user with error \(error)")
                
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    if let doc = snapshotDocuments.first {
                        
                        var user = User()
                        user.data = doc.data()
                        
                        completion(user)
                    }
                }
            }
        }
    }
    
    func deleteUserData(for user: User, completion: @escaping(Error?) -> Void) {
        guard let user = Auth.auth().currentUser?.uid else { return }
        
        print("DEBUG: Service.deleteUserData: uid: \(user)")
        
        db.collection("users").whereField("uid", isEqualTo: user).getDocuments() { querySnapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                for document in querySnapshot!.documents {
                    document.reference.delete()
                }
            }
        }
        
        let k = Auth.auth().currentUser
        
        k?.delete { error in
            if error != nil {
                print("Error deleting user")
            } else {
                print("Account deleted")
            }
        }
    }
    
    /**
     
     Updating user record for the follofing fields: homeAddress, workAddress.
     
     If both fields homeAddress and workAddress are nil or not set in User then updateUserDate will produce error - nothing to update
     
     - Parameter user: user object to update. Only homeAddress and work Address get updated
     - Parameter completion: completion handler with optional error
     
     */
    
    func updateUserData(for user: User, completion: @escaping(Error?) -> Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        print("DEBUG: Service.updateUserData: uid: \(uid)")
        
        let predicate = NSPredicate(format: "\(User.K.uid) = %@", uid)
        
        db.collection(User.K.collection).filter(using: predicate).getDocuments { querySnapshot, error in
            if let error = error {
                
                print("DEBUG: Service.updateUserData: failed to fetch user with error \(error)")
                
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    if let doc = snapshotDocuments.first {
                        
                        var update = [AnyHashable : Any]()
                        
                        if let homeAddress = user.homeAddress {
                            
                            update[FavoriteLocationType.home.key] = homeAddress
                            
                        }
                        
                        if let workAddress = user.workAddress {
                            
                            update[FavoriteLocationType.work.key] = workAddress
                            
                        }
                        
                        if update.count > 0 {
                            
                            print("DEBUG: Service.updateUserData: updating uid \(uid) with update: \(update)")
                            
                            doc.reference.updateData(update, completion: completion)
                            
                        } else {
                            
                            let error = NSError(
                                domain: "AppErrorDomain",
                                code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "Nothing to update for \(user)"
                                ]
                            )
                            
                            completion(error)
                        }
                        
                    }
                }
            }
        }
    }
    
    
    
    func fetchTripData(for id: String, completion: @escaping(Trip) -> Void) {
        
        print("DEBUG: Service.fetchTripData: Fetch trip data: id: \(id)")
        
        let predicate = NSPredicate(format: "\(Trip.K.id) = %@", id)
        
        db.collection(Trip.K.collection).filter(using: predicate).getDocuments { querySnapshot, error in
            if let error = error {
                
                print("DEBUG: Service.fetchTripData: failed to fetch trip with error \(error)")
                
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    
                    if let doc = snapshotDocuments.first {
                        
                        var trip = Trip()
                        trip.data = doc.data()
                        
                        completion(trip)
                    }
                }
            }
        }
    }
    
    func unloadTrip(trip: Trip, completion: @escaping(Bool) -> Void ) {
        
        print("DEBUG: Service.unloadTrip: \(trip)")
        
        if trip.uid == "" {
            
            print("DEBUG: Service.unloadTrip: Can not upload the trip with empty user ID \(trip)")
            
            completion(false)
            
            return
        }
        
        db.collection(Trip.K.collection).addDocument(data: trip.data) { error in
            
            if let error = error {
                
                print("DEBUG: Service.unloadTrip: Failed to upload trip with error \(error.localizedDescription)")
                
                completion(false)
                
            } else {
                
                completion(true)
                
            }
            
        }
        
    }
    
    func setDriverLocationObserver(driverUid: String, observer: @escaping(CLLocation) -> Void) -> ListenerRegistration {
        
        let listener = db.collection(Driver.K.collection).document(driverUid).addSnapshotListener { documentSnapshot, error in
            
            guard let document = documentSnapshot else {
                
                print("DEBUG: Service.setDriverLocationObserver: Error fetching location: \(error!.localizedDescription)")
                return
                
            }
            
            guard let data = document.data() else {
                
              print("DEBUG: Service.setDriverLocationObserver: Location data was empty.")
                
              return
                
            }
            
            if let l = data["l"] as? [Double?], let lat = l[0], let lon = l[1] {
                
                let location = CLLocation(latitude: lat, longitude: lon)
                
                observer(location)
                
            }
            
        }
        
        return listener
    }
    
    func setTripObserver(uid: String? = nil, for id: String? = nil, _ observer: @escaping([Trip]) -> Void) -> ListenerRegistration {
        
        var predicate: NSPredicate
        
        if let id = id {
            
            predicate = NSPredicate(format: "\(Trip.K.id) = %@", id)
            
        } else {
            
            predicate = NSPredicate(format: "\(Trip.K.status) = %d", TripStatus.isRequested.rawValue)
            
        }
        
        if let uid = uid {
            
            
            predicate = NSPredicate(format: "\(Trip.K.status) < %d AND \(Trip.K.uid) = %@", TripStatus.isCompleted.rawValue, uid)
            
        }
        
        let listener = db.collection(Trip.K.collection).filter(using: predicate).addSnapshotListener {
            querySnapshot, error in

            var trips = [Trip]()
            
            if let error = error {
                
                print("DEBUG: Sevice.setTripObserver: Trip Observation Error: \(error.localizedDescription)")
                
                observer(trips)
                
                return
            }
            
            if let snapshotDocuments = querySnapshot?.documents  {
                
                
                for doc in snapshotDocuments {
                    
                    let data = doc.data()
                    
                    var trip = Trip()
                    
                    trip.data = data
                    
                    trips.append(trip)
                    
                }
            }
            
            observer(trips)
        }
        
        return listener
    }
    
    
    func acceptTrip(trip: Trip, completion: @escaping(Any?, Error?) -> Void) {
        
        guard let driverUid = Auth.auth().currentUser?.uid else { return }
        
        let predicate = NSPredicate(format: "\(Trip.K.status) = %d AND \(Trip.K.id) = %@", TripStatus.isRequested.rawValue, trip.id)
        
        db.collection(Trip.K.collection).filter(using: predicate).getDocuments {
            querySnapshot, error in
            
            if let error = error {
                
                print("DEBUG: Service.acceptTrip: Failed to select document with error:\(error.localizedDescription)")
                
                completion(nil, error)
                
                return
                
            }
            
            if let tripRef = querySnapshot?.documents.first?.reference {
                
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                    
                    do {
                        
                        let trip = try transaction.getDocument(tripRef)
                        
                        if let status = trip.data()?[Trip.K.status] as? Int {
                            
                            if status != TripStatus.isRequested.rawValue {
                                
                                let error = NSError(
                                    domain: "AppErrorDomain",
                                    code: -1,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "wrong trip status \(trip)"
                                    ]
                                )
                                errorPointer?.pointee = error
                                
                                return nil
                            }
                            
                        }
                        
                        
                    } catch let fetchError as NSError {
                        
                        errorPointer?.pointee = fetchError
                        
                        return nil
                        
                    }
                    
                    transaction.updateData([Trip.K.driverUid: driverUid, Trip.K.status: TripStatus.isAccepted.rawValue], forDocument: tripRef)
                    
                    return nil
                    
                }, completion: completion)
                
            }
        }
        
        
    }
    
    func update(trip: Trip, to status: TripStatus? = nil, completion: @escaping(Any?, Error?) -> Void) {
        
        print("DEBUG: Sevice.update: trip: \(trip) status: \(status ?? TripStatus.isCanceled)")
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if status ?? TripStatus.isCanceled == TripStatus.isCanceled {
            
            // Only Passenger can cancel the trip, so we must check that the current user uid is recorded as trip uid
            if uid != trip.uid {
                
                print("DEBUG: Sevice.update: Only passenger can cancel the trip")
                
                return
                
            }
            
        }
        
        let predicate = NSPredicate(format: "\(Trip.K.id) = %@", trip.id)
        
        db.collection(Trip.K.collection).filter(using: predicate).getDocuments {
            querySnapshot, error in
            
            
            if let error = error {
                
                print("DEBUG: Sevice.update: Failed to select document with error:\(error.localizedDescription)")
                
                completion(nil, error)
                
                return
                
            }
            
            let locationRef = self.db.collection(Trip.K.geoCollection).document(trip.id)
            
            if let tripRef = querySnapshot?.documents.first?.reference {
                
                self.db.runTransaction({ (transaction, errorPointer) -> Any? in

                    transaction.updateData([Trip.K.status: status?.rawValue ?? TripStatus.isCanceled.rawValue], forDocument: tripRef)
                    
                    if status ?? TripStatus.isCanceled == TripStatus.isCanceled ||
                       status ?? TripStatus.isCanceled == TripStatus.isCompleted {
                        
                        transaction.deleteDocument(locationRef)
                        
                    }
                    
                    return nil
                    
                }, completion: completion)
                
            }
        }
    }
    
    func save(location: Location, completion: @escaping(Error?) -> Void) {
        
        self.db.collection(Location.K.collection).addDocument(data: location.data) { error in
            
            if let error = error {
                
                print("DEBUG: Service.save: Could not add new location with error \(error.localizedDescription)")
                
                completion(error)
                
            } else {
                
                completion(nil)
                
            }
        
        }
    }
    
    func getRouteFor(trip: Trip, and accoutType: AccountType, completion: @escaping([CLLocationCoordinate2D], Error?) -> Void ) {
        
        print("DEBUG: Service.getRouteFor: trip \(trip) and accountType: \(accoutType)")
        
        var route = [CLLocationCoordinate2D]()
        
        var predicate: NSPredicate
        
        if accoutType == .driver {
            
            predicate = NSPredicate(format: "\(Location.K.tripId) = %@ AND \(Location.K.uid) = %@", trip.id, trip.driverUid)
            
        } else {
            
            predicate = NSPredicate(format: "\(Location.K.tripId) = %@ AND \(Location.K.uid) = %@", trip.id, trip.uid)
            
        }
        
        db.collection(Location.K.collection).filter(using: predicate).order(by: Location.K.timestamp).getDocuments { querySnapshot, error in
            
            if let error = error {
                
                print("DEBUG: Service.getRouteFor: failed to fetch trip with error \(error)")
                
                completion(route, error)
                
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    
                    for doc in snapshotDocuments {
                        
                        let data = doc.data()
                        
                        var location = Location()
                        
                        location.data = data
                        
                        route.append(location.coordinates.coordinate)
                        
                    }
                    
                }
                
                var prev = CLLocationCoordinate2D(latitude: 0, longitude: 0)
                
                route = route.filter { loc in
                    
                    if loc.latitude == prev.latitude && loc.longitude == prev.longitude {
                        return false
                    } else {
                        prev = loc
                        return true
                    }
                    
                }
                
                completion(route, nil)
                
            }
            
        }

    }
    
    func getDescription(point: TripCoordinates, log:[Location]) -> String? {
        
        let first = log.first { entry -> Bool in
            
            if entry.coordinates.latitude == point.latitude && entry.coordinates.longitude == point.longitude {
                
                return entry.message != nil
                
            } else {
                
                return false
            }
        }
        
        if let first = first {
            
            return first.message
            
        } else {
            
            return nil
            
        }
        
    }
    
    func extendTripByLogEntries(_ trip: Trip, for accoutType: AccountType, completion: @escaping(Trip, Error?) -> Void ) {
        
        print("DEBUG: Service.extendTripByLogEntries: trip \(trip) and \(accoutType)")
        
        var extended = trip
        
        var route = [TripCoordinates]()
        
        var log = [Location]()
        
        var predicate: NSPredicate
        
        if accoutType == .driver {
            
            predicate = NSPredicate(format: "\(Location.K.tripId) = %@ AND \(Location.K.uid) = %@", trip.id, trip.driverUid)
            
        } else {
            
            predicate = NSPredicate(format: "\(Location.K.tripId) = %@ AND \(Location.K.uid) = %@", trip.id, trip.uid)
            
        }
        
        self.fetchUserData(for: trip.uid) { passenger in
            
            extended.passenger = passenger
            
            self.fetchUserData(for: trip.driverUid) { driver in
                
                extended.driver = driver
                
                self.db.collection(Location.K.collection).filter(using: predicate).order(by: Location.K.timestamp).getDocuments { querySnapshot, error in
                    
                    if let error = error {
                        
                        print("DEBUG: Service.extendTripByLogEntries: failed to fetch trip with error \(error)")
                        
                        completion(extended, error)
                        
                    } else {
                        
                        if let snapshotDocuments = querySnapshot?.documents {
                            
                            print("DEBUG: Service.extendTripByLogEntries: count: \(snapshotDocuments.count)")
                            
                            for doc in snapshotDocuments {
                                
                                let data = doc.data()
                                
                                var location = Location()
                                
                                location.data = data
                                
                                route.append(location.coordinates)
                                
                                log.append(location)
                                
                            }
                            
                        }
                        
                        
                        var prev = TripCoordinates(latitude: 0, longitude: 0)
                        
                        var distance: Double = 0
                        
                        var speed: Double = 0
                        
                        route = route.filter { loc in
                            
                            if loc.latitude == prev.latitude && loc.longitude == prev.longitude {
                                
                                return false
                                
                            } else {
                                
                                distance += prev.distance(from: loc)
                                
                                prev = loc
                                return true
                                
                            }
                            
                        }
                        
                        
                        route = route.map({ point -> TripCoordinates in
                            
                            if let description = self.getDescription(point: point, log: log) {
                                
                                var new = point
                                
                                new.description = description
                                
                                return new
                                
                            } else {
                                
                                return point
                            }
                        })
                        
                        if let start = log.first, let end = log.last  {
                            
                            extended.start = start.timestamp
                            extended.end = end.timestamp
                            
                            let time = end.timestamp.timeIntervalSince1970 - start.timestamp.timeIntervalSince1970
                            
                            if time > 0 {
                                
                                speed = ( distance / 1000 ) / ( time / 3600 )
                                
                            }
                            
                        }
                        
                        
                        extended.log = log
                        extended.route = route
                        extended.distance = distance
                        extended.speed = speed
                        
                        completion(extended, nil)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func getExtendedTrips(for user: User, completion: @escaping([Trip], Error?) -> Void) {
        
        print("DEBUG: Service.getExtendedTrips: user \(user)")
        
        var trips = [Trip]()
        
        var predicate: NSPredicate
        let accountType = user.accountType
        
        if accountType == .driver {
            
            predicate = NSPredicate(format: "\(Trip.K.driverUid) = %@", user.uid)
            
        } else {
            
            predicate = NSPredicate(format: "\(Trip.K.uid) = %@", user.uid)
            
        }
        
        db.collection(Trip.K.collection).filter(using: predicate).getDocuments { querySnapshot, error in
            if let error = error {
                
                print("DEBUG: Service.getExtendedTrips: failed to fetch trip with error \(error)")
                
                completion(trips, error)
                
            } else {
                
                if let snapshotDocuments = querySnapshot?.documents {
                    
                    if snapshotDocuments.count == 0 {
                        
                        completion(trips, nil)
                        
                    }
                    
                    for doc in snapshotDocuments {
                        
                        var trip = Trip()
                        
                        trip.data = doc.data()
                        
                        self.extendTripByLogEntries(trip, for: accountType) { extendedTrip , error in
                            
                            if let error = error {
                                
                                print("DEBUG: Service.getExtendedTrips: failed to extend trip with error \(error)")
                                
                                completion(trips, error)
                                
                            } else {
                                
                                trips.append(extendedTrip)
                                
                                if trips.count == snapshotDocuments.count {
                                    
                                    trips = trips.sorted(by: { t1, t2 -> Bool in
                                        
                                        if let s1 = t1.start, let s2 = t2.start {
                                            
                                            return s1.timeIntervalSince1970 < s2.timeIntervalSince1970
                                            
                                        } else {
                                            
                                            return false
                                            
                                        }
                                    })
                                    
                                    completion(trips, nil)
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}
