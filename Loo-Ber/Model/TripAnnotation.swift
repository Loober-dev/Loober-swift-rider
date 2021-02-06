//
//  TripAnnotation.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import MapKit

enum TripAnnotationType: Int, CaseIterable, CustomStringConvertible {
    
    case accepted
    case start
    case pickup
    case end
    
    var description: String {
        switch self {
        case .accepted: return "Accepted"
        case .start: return "Start"
        case .pickup: return "Pickup"
        case .end: return "End"
        
        }
    }
    
    var subtitle: String {
        switch self {
        case .accepted: return "Driver accepted the trip"
        case .start: return "Trip start"
        case .pickup: return "Driver pickup the passenger"
        case .end: return "Trip End"
        }
    }
    
    var image: UIImage {
        switch self {
        case .accepted: return UIImage(systemName: "smallcircle.fill.circle") ?? UIImage()
        case .start: return UIImage(systemName: "smallcircle.fill.circle.fill") ?? UIImage()
        case .pickup: return UIImage(systemName: "person.crop.circle.badge.plus") ?? UIImage()
        case .end: return UIImage(systemName: "stop.circle") ?? UIImage()
        }
    }
}


class TripAnnotation: NSObject, MKAnnotation {
    
    @objc dynamic var coordinate: CLLocationCoordinate2D
       
    var title: String?
       
    var subtitle: String?
    
    var type: TripAnnotationType {
        
        didSet {
            
            self.title = type.description
            self.subtitle = type.subtitle
            
        }
        
    }
    
    init(type: TripAnnotationType, coordinate: CLLocationCoordinate2D) {
        
        self.type = type
        self.coordinate = coordinate
        
    }
    
}
