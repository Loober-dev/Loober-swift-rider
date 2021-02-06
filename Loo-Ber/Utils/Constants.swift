//
//  Constants.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import CoreLocation

struct K {
    
    static let empty = ""
    static let locationInputHeight: CGFloat = 200
    static let rideActionViewHeight: CGFloat = 300
    
    static let reuseIdentifier = "LocationCell"
    static let userProfileImage = "UserProfileImage"
    static let userProfileImageFile = "UserProfileImage.png"
    static let userDriverActive = "UserDriverActive"
    
    static let sarnicoP01 = CLLocationCoordinate2D(latitude: 45.670864, longitude: 9.962422)
    static let sarnicoP02 = CLLocationCoordinate2D(latitude: 45.670790, longitude: 9.960473)
    static let sarnicoP03 = CLLocationCoordinate2D(latitude: 45.670745, longitude: 9.959164)
    static let sarnicoP04 = CLLocationCoordinate2D(latitude: 45.670767, longitude: 9.956943)
    static let sarnicoP05 = CLLocationCoordinate2D(latitude: 45.670722, longitude: 9.955452)
    static let sarnicoP06 = CLLocationCoordinate2D(latitude: 45.669890, longitude: 9.955323)
    static let sarnicoP07 = CLLocationCoordinate2D(latitude: 45.669343, longitude: 9.955806)
    static let sarnicoP08 = CLLocationCoordinate2D(latitude: 45.668863, longitude: 9.956321)
    static let sarnicoP09 = CLLocationCoordinate2D(latitude: 45.668046, longitude: 9.957287)
    static let sarnicoP10 = CLLocationCoordinate2D(latitude: 45.667604, longitude: 9.958703)
    static let sarnicoP11 = CLLocationCoordinate2D(latitude: 45.667402, longitude: 9.958714)
    static let sarnicoP12 = CLLocationCoordinate2D(latitude: 45.666945, longitude: 9.959165)
    static let sarnicoP13 = CLLocationCoordinate2D(latitude: 45.666570, longitude: 9.959422)
    static let sarnicoP14 = CLLocationCoordinate2D(latitude: 45.666173, longitude: 9.959411)
    static let sarnicoP15 = CLLocationCoordinate2D(latitude: 45.665678, longitude: 9.959250)
    static let sarnicoP16 = CLLocationCoordinate2D(latitude: 45.665678, longitude: 9.958649)
    static let sarnicoP17 = CLLocationCoordinate2D(latitude: 45.665813, longitude: 9.958048)
    static let sarnicoP18 = CLLocationCoordinate2D(latitude: 45.666023, longitude: 9.957351)
    static let sarnicoP19 = CLLocationCoordinate2D(latitude: 45.666173, longitude: 9.957029)
    static let paraticoP1 = CLLocationCoordinate2D(latitude: 45.665141, longitude: 9.956179)
    static let paraticoP2 = CLLocationCoordinate2D(latitude: 45.664731, longitude: 9.956165)
   
    
    static let fakeRoute = [
        sarnicoP01, sarnicoP02, sarnicoP03, sarnicoP04,
        sarnicoP05, sarnicoP06, sarnicoP07, sarnicoP08,
        sarnicoP09, sarnicoP10, sarnicoP11, sarnicoP12,
        sarnicoP13, sarnicoP14, sarnicoP15, sarnicoP16,
        sarnicoP17, sarnicoP18, sarnicoP19,
        
        paraticoP1, paraticoP2
    ]
    
    static let infoViewHeight: CGFloat = 250
    static let smallInfoViewHeight: CGFloat = 60
    
}
