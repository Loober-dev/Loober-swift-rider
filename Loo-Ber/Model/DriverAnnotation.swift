//
//  DriverAnnotation.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 3/26/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import Foundation
import MapKit

enum CarDirection: Int, CaseIterable, CustomStringConvertible {
    case north
    case ne
    case east
    case se
    case south
    case sw
    case west
    case nw
    
    var description: String {
        switch self {
        
        case .north: return "North"
        case .ne: return "North- East"
        case .east: return "East"
        case .se: return "South East"
        case .south: return "South"
        case .sw: return "South West"
        case .west: return "West"
        case .nw: return "North West"
        }
    }
    
    var image: UIImage {
        switch self {
        
        case .north: return #imageLiteral(resourceName: "taxi").withRenderingMode(.alwaysOriginal)
        case .ne: return #imageLiteral(resourceName: "taxi45").withRenderingMode(.alwaysOriginal)
        case .east: return #imageLiteral(resourceName: "taxi90").withRenderingMode(.alwaysOriginal)
        case .se: return #imageLiteral(resourceName: "taxi135").withRenderingMode(.alwaysOriginal)
        case .south: return #imageLiteral(resourceName: "taxi180").withRenderingMode(.alwaysOriginal)
        case .sw: return #imageLiteral(resourceName: "taxi-135").withRenderingMode(.alwaysOriginal)
        case .west: return #imageLiteral(resourceName: "taxi-90").withRenderingMode(.alwaysOriginal)
        case .nw : return #imageLiteral(resourceName: "taxi-45").withRenderingMode(.alwaysOriginal)
        }
    }
}

class DriverAnnotation: NSObject, MKAnnotation {
    
    @objc dynamic var coordinate: CLLocationCoordinate2D
    
    var title: String? = "Driver Name"
    
    var subtitle: String? = "Driver"
    
    var uid: String
    
    var bearing: Double = 0
    
    var direction: CarDirection {
        
        if bearing < -157.5 { return .south }
        else if bearing < -112.5 { return .sw }
        else if bearing < -67.5 { return .west }
        else if bearing < -22.5 { return .nw }
        else if bearing < 22.5 { return .north }
        else if bearing < 67.5 { return .ne }
        else if bearing < 112.5 { return .east }
        else if bearing < 157.5 { return .se }
        else { return .south }
        
    }
    
    var image: UIImage { direction.image }
    
    init(uid: String, coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        
        self.uid = uid
        self.coordinate = coordinate
        
        if let title = title {
            self.title = title
        }
        
        if let subtitle = subtitle {
            self.subtitle = subtitle
        }
        
    }
    
}
