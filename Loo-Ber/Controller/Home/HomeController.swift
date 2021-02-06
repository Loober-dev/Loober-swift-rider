//
//  HomeController.swift
//  Loo-Ber
//
//  Created by Emmanuel Klutse on 2/4/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import Geofirestore

/// Table view cell reusable identifier
private let reuseIdentifier = K.reuseIdentifier

/// Action button states
private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

// MARK: - HomeController Delegate

protocol HomeControllerDelegate: class {
    
    /// show hide side menu when the ActionButton is pressed in .showMenu mode
    func handleMenuToggle(with option: MenuOptions?)
    /// driver status is changed
    func driverStatusIsChanged(busy: Bool)
    
}

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    /// delegate to process handleMenuToggle calls
    weak var delegate: HomeControllerDelegate?
    
    /// Location Input Activation View. Passenger App
    private let locationInputActivationView = LocationInputActivationView()
    
    /// Location Input View. Passenger App
    private let locationInputView = LocationInputView()
    
    /// Ride Action View: Submit, Accept, PickUp, DropOff / EndOf and Cancel of the Ride - all Ride related action for both Passenger and Driver.
    private let rideActionView = RideActionView()
    
    /// Map View. Passenger / Driver App
    private let mapView = MKMapView()
    
    /// Location Handler
    private let locationManager = LocationHandler.shared.locationManager
    
    /// Placemarks table. Passenger App
    private let tableView = UITableView()
    
    /// Locaton Input View Height
    private final let locationInputHeight: CGFloat = K.locationInputHeight
    
    /// Ride Action View Height
    private final let rideActionViewHeight: CGFloat = K.rideActionViewHeight
    
    /// Current User
    var user: User? {
        
        didSet {
            
            if let fullName = user?.fullName {
                
                locationInputView.fullName = fullName
                
            }
            // Set ContainerController User object that is neede to the side menu and setings
            if let parent = parent as? ContainerController, let user = user {
                
                parent.set(user: user)
                
            }
            // set home address favorite location if it's presented in the user object
            if let homeAddress = user?.homeAddress {
                
                favoriteLocations[FavoriteLocationType.home] = homeAddress
                
            }
            // set work address favorite location if it's presented in the user object
            if let workAddress = user?.workAddress {
                
                favoriteLocations[FavoriteLocationType.work] = workAddress
            }
        }
    }
    
    /// User Favorite locations.
    ///
    /// It could be updated when the User object is set or using setFavoriteLocation(for: address:) helper function.
    /// SettingController use delegate favoriteAddressUpdated(for: address:) method call to update these values when user select / update them
    
    private var favoriteLocations: [FavoriteLocationType: String] = {
        
        var dict = [FavoriteLocationType: String]()
        
        FavoriteLocationType.allCases.forEach { dict[$0] = $0.subtitle }
        
        return dict
    }()
    
    /// Destination seach results
    private var seachResults = [MKPlacemark]()
    
    /// Selected distination
    private var destinationAnnotation: MKAnnotation?
    
    /// Route to destionation
    private var route: MKRoute?
    
    /// Activation Button
    private let actionButton : UIButton = {
        let button = UIButton(type: .system)
        
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        
        return button
    }()
    
    /// Activation Button Configuration
    private var actionButtonConfiguration = ActionButtonConfiguration()
    
    /// Current trip listener
    private var tripListener: ListenerRegistration?
    
    /// Current trip
    private var trip: Trip? {
        
        didSet {
            
            guard let trip = trip else {
                
                tripListener?.remove()
                
                if isDriver { delegate?.driverStatusIsChanged(busy: false ) }
                
                LocationHandler.shared.loggingStop()
                
                return
                
            }
            
            if !isDriver { return }
            
            delegate?.driverStatusIsChanged(busy: true)
            
            if trip.status != .isRequested { return }
            
            let pickupController = PickupController(trip: trip)
            
            pickupController.delegate = self
            
            DispatchQueue.main.async {
                
                pickupController.modalPresentationStyle = .fullScreen
                self.present(pickupController, animated: true, completion: nil)
                
            }
        }
    }
    
    /// Driver is Active
    private var isActive: Bool = true
    
    /// Check if Driver is busy with current trip. Menu Controller must check this value and disable activity switch is driver is busy
    var isBusy: Bool {
        
        trip != nil
        
    }
    
    /// Check if current user is a Driver
    private var isDriver: Bool {
        
        if let accountType = user?.accountType {
            
            return accountType == .driver
            
        } else {
            
            return false
        }
        
    }
    
    /// The passenger User object. Driver App
    private var passenger: User? {
        
        didSet {
            
            if passenger == nil { return }
            
            if !isDriver { return }
            
            if let trip = self.trip {
                
                if trip.status == .inProgress {
                    
                    DispatchQueue.main.async {
                        
                        self.prepareRideActionView()
                        
                    }
                }
            }
        }
    }
    
    /// The driver User object. Passenger App.
    private var driver: User? {
        
        didSet {
            
            guard let driver = driver else  {
                
                driverListener?.remove()
                
                return
            }
            
            if let trip = self.trip {
                
                if trip.status != .isCompleted {
                    
                    DispatchQueue.main.async {
                        
                        self.prepareRideActionView()
                        self.toggleRideActionView(show: true)
                        
                        
                    }
                    
                }
                
                if trip.status == .inProgress {
                    
                    // Now the passenger on bord we don't need to follow the the driver location because it equal to the passenger one
                    
                    print("DEBUG: Driver.didSet: remove driver Listener:")
                    driverListener?.remove()
                    
                    return
                    
                }
                
            }
    
        
            driverListener = Service.shared.setDriverLocationObserver(driverUid: driver.uid, observer: self.driverLocationListener)
        }
        
    }
    /// Listener for driver location updates. Passenger App.
    private var driverListener: ListenerRegistration?
    
    /// Driver last location. Passenger App.
    private var lastDriverLocation: CLLocation?
    
    /// Check if driver is near pickup location. Passenger App.
    private var isDriverArrivedAtPickupLocation: Bool {
        
        if let location = lastDriverLocation, let trip  = self.trip {
            
            let distance = location.distance(from: trip.pickupCoordinates.location)
            
            print("DEBUG: HC.isDriverArrivedAtPickupLocation: distance: \(distance)")
            print("DEBUG: HC.isDriverArrivedAtPickupLocation: radius: \(LocationHandler.regionRadius)")
            
            return ( distance < LocationHandler.regionRadius )
            
        } else {
            
            return false
        }
        
    }
    
    /// Check if User (Driver or Passenger) is near destination location.
    private var isUserArrivedAtDestination: Bool {
        
        if let location = locationManager?.location, let trip = self.trip {
            
            let distance = location.distance(from: trip.destinationCoordinates.location)
            
            print("DEBUG: HC.isUserArrivedAtDestination: distance: \(distance)")
            print("DEBUG: HC.isUserArrivedAtDestination: radius: \(LocationHandler.regionRadius)")
            
            return ( distance < LocationHandler.regionRadius )
            
        } else {
            return false
        }
        
    }
    
    /// Check if User that has to be Driver Account Type is near pickup location
    private var isUserAsDriverArrivedAtPickupLocation: Bool {
        
        if let location = locationManager?.location, let trip = self.trip {
            
            let distance = location.distance(from: trip.pickupCoordinates.location)
            
            print("DEBUG: HC.isUserAsDriverArrivedAtPickupLocation: distance: \(distance)")
            print("DEBUG: HC.isUserAsDriverArrivedAtPickupLocation: radius: \(LocationHandler.regionRadius)")
            
            return ( distance < LocationHandler.regionRadius )
            
        } else {
            return false
        }
        
    }
    
    /// Check if current trip is in progress state.
    private var tripInProgress: Bool {
        
        if let trip = self.trip {
            
            return trip.status == .inProgress
            
        }
        
        return false
    }
    
    
    // MARK: - Lifecycle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if checkIfUserLoggedIn() {
        
            configure()
            
        } else {
            
            presentLoginSignUp()
                
        }
        
        
    }
    // MARK: - Selectors
    
    /**
     
     Process action button pressed event. The action button has two states : .dismissActionView or .showMenu . The first one is active during location input and the second one is default value to show left side menu.
     
     */
    
    @objc func actionButtonPressed() {
        
        switch actionButtonConfiguration {
            
        case .dismissActionView:
            print("DEBUG: HC.actionButtonPressed.dismissActionView")
            
            UIView.animate(withDuration: 0.3, animations:  {
                
                self.locationInputActivationView.alpha = 1
                self.toggleActionButton()
                self.removeAnnotationAndOverlay()
                
                }) { _ in
                    
                    UIView.animate(withDuration: 1) {
                        
                        self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                        
                        self.toggleRideActionView(show: false)
                        
                    }
                    
                }
            
        case .showMenu:
            print("DEBUG: HC.actionButtonPressed.showMenu")
            delegate?.handleMenuToggle(with: nil)
            
        }
    }
    
    // MARK: - API
    
    /**
     
     Check if user is logged in
     
     */
    
    func checkIfUserLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    
    
    // MARK: - Helpers
    
    /**
     Set active status for the driver.
     
     This function calls Container Controller when User has changed activity status in the Side Menu. Activity status is availible only for Driver and if Driver is not active he is not listening for incoming trips. If driver isBusy take no actiin.
     
     - Parameter active: true if active
     
     */
    
    func setActive(to active: Bool) {
        
        print("DEBUG: HC.setActive: isBusy \(isBusy) isActive: \(self.isActive) change to \(active)")
        
        if isBusy { return }
        
        if self.isActive != active {
            
            self.isActive = active
            
            if active {
                
                if let user = self.user {
                    
                    print("DEBUG: HC.setActive: Set Driver Status to: Active")
                    
                    LocationHandler.shared.delegate = self
                    
                    LocationHandler.shared.enableLocationSevices(for: .driver)
                    
                    LocationHandler.shared.enableGeofirestoreUpdates(for: .driver, uid: user.uid)
                    
                }
                
            } else {
                
                print("DEBUG: HC.setActive: Set Driver Status to: Unactive")
                
                LocationHandler.shared.disableGeofirestoreUpdates()
                
                LocationHandler.shared.removeAllObservers()
                
                LocationHandler.shared.delegate = nil
                
            }
            
        }
 
    }
    
    /**
     Set favorite address for the given favorite location type (work or home)
     
     NOTE! We are not updating User structure to be in sync with favoriteLocations, but suppose that this function call is made after the User record was updated in Firestore database and next time when User is uploaded from Firestore the favorite location will be in sync because we are setting them when we set new object for the User using didSet hook.
     
     - Parameter option: favorite location type: work or home
     - Parameter address: address to be stored as a new favorire location address
     
     */
    
    func setFavoriteLocation(for option: FavoriteLocationType, address: String) {
        
        print("DEBUG: HC.setFavoriteLocation: for: \(option), address \(address)")
        
        favoriteLocations[option] = address
        
    }
    
    func presentLoginSignUp() {
       
        let loginController = LoginController()
        
        let nc = UINavigationController(rootViewController: loginController)
        
        DispatchQueue.main.async {
            
            nc.modalPresentationStyle = .fullScreen
            self.present(nc, animated: true, completion: nil)
            
        }
        
    }
    
    func checkUI() -> Bool {
        
        print("DEBUG: HC.checkUI: UI is ready: \((view.subviews.first { $0 is MKMapView } != nil))")
        
        return (view.subviews.first { $0 is MKMapView } != nil)
    }
    
    
    /**
     
     Configure User Interface
     
     */
    
    func configureUI() {
        
        if checkUI() { return }
        
        configureMapView()
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,  paddingTop: 16, paddingLeft: 20, width: 30, height: 30)
        
        
        configureTableView()
        
    }
    
    /**
     
     Configure Location input activation view for passenger APP
     
     */
    
    func configureLocationInputActivationView() {
        
        view.addSubview(locationInputActivationView)
        locationInputActivationView.centerX(inView: view)
        locationInputActivationView.setDimension(height: 50, width: view.frame.width - 64)
        locationInputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        
        locationInputActivationView.alpha = 0
        
        locationInputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) {
            
            self.locationInputActivationView.alpha = 1
            
        }
        
    }
    
    /**
     
     Configure map view
     
     */
    func configureMapView() {
        
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        mapView.delegate = self
        
    }
    
    /**
     
     Configure Home View Controller including User Interface and User setup
     
     */
    func configure() {
        
        print("DEBUG: HC.configure")
        
        configureUI()
        
        setupUser()
        
    }
    
    /**
     
     Reset UI to the initial state. Driver and User App.
     
     */
    func resetUI() {
        
        DispatchQueue.main.async {
            
            self.mapView.removeAllAnnotationsAndOverlays()
            
            self.toggleRideActionView(show: false)
            
            UIView.animate(withDuration: 0.2) {
                
                self.resetActionButton()
                
                if !self.isDriver { self.locationInputActivationView.alpha = 1 }
                
                self.setupUser()
                
                self.centerMapOnUserLocation()
                
            }
            
        }
    }
    
    /**
     
     Configure Location Input View. Passenger App
     
     */
    func configureLocationInputView() {
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: locationInputHeight)
        
        locationInputView.alpha = 0
        locationInputView.delegate = self
        
        self.tableView.reloadData()
        
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 1
        }) { _ in
            print("DEBUG: Present Input location view")
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputHeight
            }
        }
    }
    
    /**
     
     Configure table view for locations. Passenger App
     
     */
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationInputCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - locationInputHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        view.addSubview(tableView)
    }
    
    /**
     
     Configure Ride Action View
     
     */
    func configureRideActionView() {
        
        rideActionView.delegate = self
        
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
        
        view.addSubview(rideActionView)
        
    }
    
    
    
    /**
     
     Dismiss location input view for passenger App
     
     */
    func dismissLocationInputViewWith(completion: ((Bool) -> Void)? = nil) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
        }) { _ in
            UIView.animate(withDuration: 0.3, animations:  {
                self.locationInputView.removeFromSuperview()
                // self.locationInputActivationView.alpha = 1
            }, completion: completion)
            
        }
    }
    
    /**
     
     Toggle Action Button
     
     */
    func toggleActionButton() {
        
        if actionButtonConfiguration == .dismissActionView {
            
            actionButtonConfiguration = .showMenu
            actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            
        } else {
            
            actionButtonConfiguration = .dismissActionView
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
            
        }
    }
    
    /**
     
     Reset Action button to the initial state
     
     */
    func resetActionButton() {
        
        actionButtonConfiguration = .showMenu
        actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        
    }
    
    /**
     
     Show / hide Ride Action View
     
     - Parameter show: if **true** the RideActionView shows
     
     */
    func toggleRideActionView(show: Bool) {
        
        print("DEBUG: HC.toggleRideActionView: show \(true)")
        
        if self.rideActionView.frame.origin.y == self.view.frame.height - (show ? self.rideActionViewHeight : 0) {

            return

        }
        
        
        UIView.animate(withDuration: 0.3) {
            
            self.rideActionView.frame.origin.y = self.view.frame.height - (show ? self.rideActionViewHeight : 0)
            
        }
    }
    
}

// MARK: - Driver / Passenger App

private extension HomeController {
    
    /**
     
     Setup current user. Fetch user object from Firestore database and setup passenger or driver specific application
     
     */
    func setupUser() {
        
        Service.shared.fetchUserData { user  in
            
            self.user = user
            
            if user.accountType == .passenger {
                
                print("DEBUG: HC.setupUser: Passenger App Configuration")
                
                LocationHandler.shared.delegate = self
                
                LocationHandler.shared.enableLocationSevices(for: .passenger)
                
                self.configureLocationInputActivationView()
                
                self.tripListener = Service.shared.setTripObserver(uid: user.uid, self.passengerTripListener)
                
            } else if user.accountType == .driver {
                
                print("DEBUG: HC.setupUser: Driver App Configuration")
                
                print("DEBUG: HC.setupUser: Driver is Active: \(self.isActive)")
                
                if user.isActive {
                    
                    print("DEBUG: HC.setupUser: Setup active Driver")
                    
                    LocationHandler.shared.delegate = self
                    
                    LocationHandler.shared.enableLocationSevices(for: .driver)
                    
                    LocationHandler.shared.enableGeofirestoreUpdates(for: .driver, uid: user.uid)
                    
                } else {
                    
                    print("DEBUG: HC.setupUser: Driver is unactive. Nothing to setup")
                    
                     self.presentAlertController(withMessage: "You will not recieve trip requests. Change the mode in side menu.", and: "Unactive mode!")
                    
                }
            }
        }
    }
    
    /**
     
     Show progress of User (Driver or Passenger) to the destination location
     
     */
    
    func progressOfUserToDestinationLocation() {
        
        print("DEBUG: HC.progressOfUserToDestinationLocation")
        
        if let trip = self.trip {
            
            print("DEBUG: HC.progressOfUserToDestinationLocation: \(trip)")
            print("DEBUG: HC.progressOfUserToDestinationLocation: annotations: \(self.mapView.annotations.count)")
            
            self.mapView.removeAllOverlays()
            // self.removeAllDriverAnnotations()
            
            if self.mapView.annotations.count < 2 {
                
                print("DEBUG: HC.progressOfUserToDestinationLocation: adding destination annotation")
                
                LocationHandler.shared.lookUpLocation(trip.destinationCoordinates.location) { placemark in
                    
                    var address = "Destination Address"
                    
                    if let placemark = placemark {
                        
                        address = MKPlacemark(placemark: placemark).address
                        
                    }
                    
                    let destinationAnnotation = MKPointAnnotation()
                    destinationAnnotation.coordinate = trip.destinationCoordinates.coordinate
                    destinationAnnotation.title = address
                    
                    self.mapView.addAnnotation(destinationAnnotation)
                    
                    let annotations = self.getZoomAnnotations()
                    
                    print("DEBUG: HC.progressOfUserToDestinationLocation: annotations: \(annotations.count)")
                    
                    UIView.animate(withDuration: 1) {
                        
                        self.mapView.zoomToFit(annotations: annotations)
                        
                    }
                    
                }
                
            } else {
                
                let annotations = self.getZoomAnnotations()
                
                UIView.animate(withDuration: 1) {
                    
                    self.mapView.zoomToFit(annotations: annotations)
                    
                }
                
            }
            
            if !isUserArrivedAtDestination {
                
                let coordinate = trip.destinationCoordinates.coordinate
                let destinationPlacemark = MKPlacemark(coordinate: coordinate)
                let destination = MKMapItem(placemark: destinationPlacemark)
                
                generatePolyline(toDestination: destination)
            }
            
            
        }
        
    }
    
    /**
     
     Prepare Ride Action View for User ( Driver and Passenger )
     
     */
    
    func prepareRideActionView() {
        
        print("DEBUG: prepareRideActionView")
        
        if isDriver {
            
            print("DEBUG: prepareRideActionView: Driver ")
            
            if let passenger = self.passenger, let trip = self.trip {
                
                print("DEBUG: prepareRideActionView: passenger: \(passenger)")
                print("DEBUG: prepareRideActionView: trip: \(trip)")
                
                if trip.status == .isAccepted {
                    
                    LocationHandler.shared.lookUpLocation(trip.pickupCoordinates.location) { placemark in
                        
                        var address = "Pickup Address"
                        
                        if let placemark = placemark {
                            
                            address = MKPlacemark(placemark: placemark).address
                            
                        }
                        
                        if !self.isUserAsDriverArrivedAtPickupLocation {
                            
                            DispatchQueue.main.async {
                                
                                let config : RideActionViewConfiguration = .tripAccepted((.driver, address, passenger.fullName))
                                self.rideActionView.configureUI(withConfig: config)
                                self.toggleRideActionView(show: true)
                                
                            }
                            
                            
                        } else {
                            
                            DispatchQueue.main.async {
                                
                                let config : RideActionViewConfiguration = .pickupPassenger((.driver, address, passenger.fullName))
                                self.rideActionView.configureUI(withConfig: config)
                                self.toggleRideActionView(show: true)
                                
                            }
                        }
                        
                    }
                    
                } else if trip.status == .inProgress {
                    
                    LocationHandler.shared.lookUpLocation(trip.destinationCoordinates.location) { placemark in
                        
                        var address = "Destination Address"
                        
                        if let placemark = placemark {
                            
                            address = MKPlacemark(placemark: placemark).address
                            
                        }
                        
                        if self.isUserArrivedAtDestination {
                            
                            DispatchQueue.main.async {
                                let config: RideActionViewConfiguration = .endTrip((.driver, address, passenger.fullName ))
                                self.rideActionView.configureUI(withConfig: config)
                                self.toggleRideActionView(show: true)
                            }
                            
                        } else {
                            
                            DispatchQueue.main.async {
                                let config: RideActionViewConfiguration = .tripInProgress((.driver, address, passenger.fullName ))
                                self.rideActionView.configureUI(withConfig: config)
                                self.toggleRideActionView(show: true)
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            
            print("DEBUG: prepareRideActionView: Passenger ")
            
            if let trip = self.trip {
                
                print("DEBUG: prepareRideActionView: trip \(trip) ")
                
                if trip.status == .isAccepted {
                    
                    if let driver = self.driver {
                        
                        print("DEBUG: prepareRideActionView: driver: \(driver) ")
                        print("DEBUG: prepareRideActionView: isDriverArrived: \(isDriverArrivedAtPickupLocation) ")
                        
                        if isDriverArrivedAtPickupLocation {
                            
                            let config: RideActionViewConfiguration = .driverArrived((.passenger, K.empty, driver.fullName ))
                            self.rideActionView.configureUI(withConfig: config)
                            
                        } else {
                            
                            let config: RideActionViewConfiguration = .tripAccepted((.passenger, "Wait for the driver at pickup location", driver.fullName ))
                            self.rideActionView.configureUI(withConfig: config)
                            
                        }
                        
                    }
                    
                } else if trip.status == .inProgress {
                    
                    if let driver = self.driver {
                        
                        print("DEBUG: prepareRideActionView: driver: \(driver) ")
                        print("DEBUG: prepareRideActionView: isUserArrived: \(isUserArrivedAtDestination) ")
                        
                        LocationHandler.shared.lookUpLocation(trip.destinationCoordinates.location) { placemark in
                            
                            var address = "Destination Address"
                            
                            if let placemark = placemark {
                                
                                address = MKPlacemark(placemark: placemark).address
                                
                            }
                            
                            if self.isUserArrivedAtDestination {
                                
                                let config: RideActionViewConfiguration = .endTrip((.passenger, address, driver.fullName ))
                                self.rideActionView.configureUI(withConfig: config)
                                
                            } else {
                                
                                let config: RideActionViewConfiguration = .tripInProgress((.passenger, address, driver.fullName ))
                                self.rideActionView.configureUI(withConfig: config)
                                
                            }
                            
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}

// MARK: - Passenger App

private extension HomeController {
    
    /**
     
     Trip listener. Passenger App.
     
     */
    func passengerTripListener(trips: [Trip]) -> Void {
        
        if let trip = trips.first {
            
            if trip.status != .isRequested {
                
                self.shouldPresentLoadingView(false)
                
            }
            
            print("DEBUG: HC.passengerTripListener: not completed trip update")
            
            self.locationInputActivationView.alpha = 0
            
            self.resetActionButton()
            
            
            
            LocationHandler.shared.removeAllObservers()
            
            self.trip = trip
            
            if trip.driverUid != K.empty {
                
                Service.shared.fetchUserData(for: trip.driverUid) { driver in
                    
                    print("DEBUG: HC.passengerTripListener: Driver for trip is found: \(driver)")
                    
                    self.driver = driver
                    
                    if trip.status == .isAccepted {
                        
                        self.progressOfDriverToPickupLocation()
                        
                    } else if trip.status == .inProgress {
                        
                        LocationHandler.shared.loggingStart(trip: trip, status: .inProgress)
                        
                        self.mapView.removeAllAnnotationsAndOverlays()
                        self.progressOfUserToDestinationLocation()
                        
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    /**
     
     Driver Location Listener. Passenger App.
     
     - Parameter location: new driver location
     
     
     */
    func driverLocationListener(location: CLLocation) {
        
        if let lastLocation = self.lastDriverLocation {
            
            if lastLocation.distance(from: location) < 30 {
                
                return
                
            }
        }
        
        DispatchQueue.main.async {
            
            self.lastDriverLocation = location
            self.progressOfDriverToPickupLocation()
            self.prepareRideActionView()
            
        }
        
    }
    
    /**
     
     Show to passenger the current trip driver rout to current user location. Passenger App
     
     
     */
    func progressOfDriverToPickupLocation() {
        
        print("DEBUG: HC.progressOfDriverToPickupLocation")
        
        if let location = self.lastDriverLocation, let driver = self.driver {
            
            let coordinate = location.coordinate
            
            if let annotation = self.getAnnotationBy(uid: driver.uid) {
                
                UIView.animate(withDuration: 0.3) {
                    
                    let bearing = annotation.coordinate.getBearing(point: coordinate)
                    
                    print("DEBUG: HC.progressOfDriverToPickupLocation: bearing: \(bearing)")
                    
                    annotation.coordinate = coordinate
                    annotation.bearing = bearing
                    
                    if let annotationView = self.mapView.view(for: annotation) {
                        
                        annotationView.image = annotation.image
                        
                    }
                    
                }
                
            } else {
                
                let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate, title: driver.fullName)
                
                UIView.animate(withDuration: 0.2) {
                    
                    self.mapView.addAnnotation(annotation)
                    
                }
                
            }
            
            if mapView.overlays.count > 0 {
                
                if let overlay = mapView.overlays.first {
                    
                    mapView.removeOverlay(overlay)
                    
                }
                
            }
            
            if !isDriverArrivedAtPickupLocation {
                
                let driverPlacemark = MKPlacemark(coordinate: coordinate)
                let destination = MKMapItem(placemark: driverPlacemark)
                
                generatePolyline(toDestination: destination)
            }
            
            
            let annotations = self.getZoomAnnotations(include: driver.uid)
            
            UIView.animate(withDuration: 1) {
                
                self.mapView.zoomToFit(annotations: annotations)
                
                
            }
            
            
        }
        
        
    }
}

// MARK: - Driver App

private extension HomeController {
    
    /**
     
      Trip Listener. Driver App.
     
     - Parameter trips: Trip array to process
     
     */
    func driverTripListener(trips: [Trip]) -> Void {
        
        if let trip = trips.first {
            
            print("DEBUG: HC.driverTripListener: \(trip)")
            
            Service.shared.fetchUserData(for: trip.uid) { user in
                
                self.passenger = user
                self.trip = trip
                
                print("DEBUG: HC.driverTripListener: trip id \(trip.id) is updated")
                print("DEBUG: HC.driverTripListener: passenger \(user)")
                
                
                if trip.status == .isAccepted {
                    
                    LocationHandler.shared.loggingStart(trip: trip, status: .isAccepted)
                    
                    /// **True** if the pickup region monitoring is started and driver IS NOT yet arrived at the pickup location. **False** if driver has been arrived and can pickup the passenger. For more information see `LocationHandler`
                    
                    let startRegionMonitoring = LocationHandler.shared.setCustomRegion(withCoordinates: trip.pickupCoordinates.coordinate)
                    
                    
                    print("DEBUG: HC.driverTripListener: trip id \(trip.id) is arrived to pickup location \(!startRegionMonitoring)")
                    
                    DispatchQueue.main.async {
                        
                        self.driverRoutToPickupLocation(for: trip, isArrived: !startRegionMonitoring)
                        
                    }
                    
                    
                } else if trip.status == .isCanceled {
                    
                    print("DEBUG: HC.driverTripListener: Trip is canceled by the passenger")
                    
                    LocationHandler.shared.log(status: .isCanceled, message: "Trip is canceled by the passenger")
                    
                    LocationHandler.shared.loggingStop()
                    
                    self.trip = nil
                    self.passenger = nil
                    
                    DispatchQueue.main.async {
                        
                        self.mapView.removeAllAnnotationsAndOverlays()
                        
                        self.toggleRideActionView(show: false)
                        
                        self.centerMapOnUserLocation()
                        
                        self.presentAlertController(withMessage: "The passenger is cancel this tip", and: "Uh no!")
                        
                    }
                    
                } else if trip.status == .inProgress {
                    
                    print("DEBUG: HC.driverTripListener: Trip is in progress")
                    
                    LocationHandler.shared.log(status: .inProgress, message: nil)
                    
                    // Stop region monitoring for the pickup location
                    LocationHandler.shared.stopRegionMonitoring()
                    
                    /// **True** if the destination region monitoring is started and user IS NOT yet arrived at the destination location. **False** if user has been arrived to destination. For more information see `LocationHandler`
                    
                    let startRegionMonitoring = LocationHandler.shared.setCustomRegion(withCoordinates: trip.destinationCoordinates.coordinate, type: .destination)
                    
                    print("DEBUG: HC.driverTripListener: trip id \(trip.id) is arrived to destination  \(!startRegionMonitoring)")
                    
                    DispatchQueue.main.async {
                        
                        self.mapView.removeAllAnnotationsAndOverlays()
                        self.prepareRideActionView()
                        self.progressOfUserToDestinationLocation()
                        
                        
                    }
                    
                }
            }
            
        }
        
    }
    
    /**
     
     Show rout to passenger pickup location for the driver. Driver App
     
     - Parameter trip: current trip
     - Parameter isArrived: If true then the current driver location is in the pickup region
     
     */
    func showDriverRouteToPickupLocation(for trip: Trip, isArrived: Bool) {
        
        print("DEBUG: HC.showDriverRouteToPickupLocation: trip\(trip) isArrived: \(isArrived)")
        
        self.mapView.removeAllAnnotationsAndOverlays()
        
        let passengerAnnotation = MKPointAnnotation()
        passengerAnnotation.coordinate = trip.pickupCoordinates.coordinate
        passengerAnnotation.title = passenger?.fullName ?? "Passenger"
        
        if !isArrived {
            
            let passengerPlacemark = MKPlacemark(coordinate: trip.pickupCoordinates.coordinate)
            let destination = MKMapItem(placemark: passengerPlacemark)
            
            generatePolyline(toDestination: destination)
            
        }
        
        
        self.mapView.addAnnotation(passengerAnnotation)
        self.mapView.selectAnnotation(passengerAnnotation, animated: true)
        
        let annotations = self.getZoomAnnotations()
        
        UIView.animate(withDuration: 1) {
            
            self.mapView.zoomToFit(annotations: annotations)
            
        }
        
    }
    
    /**
     
     Setup and show the driver rout to pickup location. Driver App
     
     - Parameter trip: current trip
     - Parameter isArrived: If true then the current driver location is in the pickup region
     
     */
    func driverRoutToPickupLocation(for trip: Trip, isArrived: Bool) {
        
        self.prepareRideActionView()

        showDriverRouteToPickupLocation(for: trip, isArrived: isArrived)
        
    }
}


// MARK: - Map Extensions

private extension HomeController {
    
    /**
     
     Seach for placemarks
     
     - Parameter naturalLanguageQuery: query to seach
     - Parameter compleation: compleation handler for seach results
     
     */
    
    func seachBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let seach = MKLocalSearch(request: request)
        
        seach.start { (response, error) in
            
            if let error = error {
                
                print("DEBUG: Serach ended with error: \(error.localizedDescription)")
                completion(results)
            }
            
            guard let response = response else { return }
            
            response.mapItems.forEach ({ item in
                
                results.append(item.placemark)
            })
            
            completion(results)
        }
    }
    
    /**
    
     Generate polyline from current user loication (driver or passenger) to given distination
     
     - Parameter destination: polyline target destination
     
     */
    
    func generatePolyline(toDestination destination: MKMapItem) {
        
        let request = MKDirections.Request()
        
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        
        directionRequest.calculate { response, error in
            
            if let error = error {
                
                print("DEBUG: direction request failed with error : \(error.localizedDescription)")
                
                return
                
            }
            
            guard let response = response else { return }
            
            self.route = response.routes.first
            
            guard let polyline = self.route?.polyline else {
                
                print("DEBUG: Failed to create lopyline for route")
                
                return
                
            }
            
            self.mapView.addOverlay(polyline)
        }
        
    }
    
    /**
     
     Remove destination annotation and polyline overlay from the map
     
     */
    func removeAnnotationAndOverlay() {
        
        if let annotation = destinationAnnotation {
            
            mapView.removeAnnotation(annotation)
            
            destinationAnnotation = nil
            
        }
        
        if mapView.overlays.count > 0 {
            
            if let overlay = mapView.overlays.first {
                
                mapView.removeOverlay(overlay)
                
            }
            
        }
       
    }
    
    
    /**
     
     Get array of annotations for Zoom
     
     - Parameter driverUid: optional driver uid to include
     
     */
    func getZoomAnnotations(include driverUid: String? = nil) -> [MKAnnotation] {
        
        var annotations = [MKAnnotation]()
        
        mapView.annotations.forEach { annotation in
            
            if let anno = annotation as? MKUserLocation {
                
                annotations.append(anno)
                
            } else if let anno = annotation as? MKPointAnnotation {
                
                if driverUid == nil {
                    
                    annotations.append(anno)
                    
                }
                
            } else if let anno = annotation as? DriverAnnotation {
                
                if let uid = driverUid {
                    
                    if uid == anno.uid {
                        
                        annotations.append(anno)
                        
                    }
                    
                }
                
            }
        }
        
        return annotations
    }
    
    /**
     
     Center map vew on the current user location
     
     */
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - MKMapViewDelegate Protocol

extension HomeController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let annotation = annotation as? DriverAnnotation {
            
            let reuseIdentifier = NSStringFromClass(DriverAnnotation.self)
            
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            
            
            annotationView.canShowCallout = true
            
            annotationView.image = annotation.image
            
            print("DEBUG: CH.mapView: annotation: bearing: \(annotation.bearing)")
            
            return annotationView
            
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let route = self.route {

            let polyline = route.polyline
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .mainBlueTint
            renderer.lineWidth = 4

            return renderer
        }

        return MKPolylineRenderer()

    }
}


// MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    
    func presentLocationInputView() {
        locationInputActivationView.alpha = 0
        configureLocationInputView()
    }
    
    
}

// MARK: - LocationInputDelegate

extension HomeController: LocationInputViewDelegate {
    
    /**
     
     Execute Seach for given query
     
     - Parameter query: string to seach
     
     */
    func executeSerach(query: String) {
        print("DEBUG: query: \(query)")
        
        seachBy(naturalLanguageQuery: query) { placemarks in
            self.seachResults = placemarks
            
            self.tableView.reloadData()
        }
    }
    
    /**
     
     Dismiss Location Input View
     
     */
    func dismissLocationInputView() {
        
        dismissLocationInputViewWith { _ in
            UIView.animate(withDuration: 0.3) {
                 self.locationInputActivationView.alpha = 1
            }
        }
    }
}

// MARK: - TableView Delegate/DataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        " "
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        favoriteLocations.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 2 : seachResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationInputCell
        
        if indexPath.section == 1 {
            
            let pm = seachResults[indexPath.row]
            
            cell.configureCell(title: pm.name ?? " ", address: pm.address)
            
        } else if indexPath.section == 0 {
            
            guard let option = FavoriteLocationType(rawValue: indexPath.row) else { return cell }
            
            if let favoriteAddress = favoriteLocations[option] {
                
                cell.configureCell(title: option.description, address: favoriteAddress)
                
            }
            
        }
        
        
        return cell
    }
    
    func showRouteToSelectedPlacemark(_ placemark: MKPlacemark) {
        
        toggleActionButton()
        
        let destination = MKMapItem(placemark: placemark)
        
        generatePolyline(toDestination: destination)
            
        dismissLocationInputViewWith { _ in
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = placemark.coordinate
            annotation.title = placemark.name
            annotation.subtitle = placemark.address
            
            let config: RideActionViewConfiguration = .requestRide((.passenger, placemark.name ?? "Destination", placemark.address))
            
            self.rideActionView.configureUI(withConfig: config)
        
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)
            
            self.destinationAnnotation = annotation
            
            let annotations = self.getZoomAnnotations()
            
            UIView.animate(withDuration: 1) {
                
                self.mapView.zoomToFit(annotations: annotations)
                
                self.toggleRideActionView(show: true)
                
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DEBUG: Row selected at index \(indexPath.row)")
        
        if indexPath.section == 0 {
            
            guard let option = FavoriteLocationType(rawValue: indexPath.row) else { return  }
            
            if favoriteLocations[option] == option.subtitle {
                
                // Found default cell value need to update it
                
                dismissLocationInputViewWith { _ in
                    
                    self.resetActionButton()
                
                    self.locationInputActivationView.alpha = 1
                    
                    self.delegate?.handleMenuToggle(with: .settings)
                    
                    
                }
                
            } else {
                
                // set location ...
                
                if let address = favoriteLocations[option] {
                    
                    LocationHandler.shared.getPlacemark(for: address) { placemark, error in
                        
                        if let error = error {
                            
                            print("DEBUG: HC.tableView.didSelectRowAt: Failed to convert the favorite address \(address) to placemark with error \(error.localizedDescription)")
                            
                        } else {
                            
                            if let placemark = placemark {
                                
                                let favoritePlacemark = MKPlacemark(placemark: placemark)
                                
                                self.showRouteToSelectedPlacemark(favoritePlacemark)
                                
                            }
                            
                            
                        }
                        
                        
                    }
                    
                }
                
                
            }
            
            
        } else {
            
            showRouteToSelectedPlacemark(seachResults[indexPath.row])
            
        }
        
        
    }
    
    
}

// MARK: - LocationHandlerDelegate Protocol

extension HomeController: LocationHandlerDelegate {
    
    /**
     
     Driver Location updated to the new location
     
     - Parameter location: new driver location
     
     */
    func driverLocationUpdatedToNew(location: CLLocation) {
        
        if !isDriver { return }
        
        print("DEBUG: HC.driverLocationUpdatedToNew: location: \(location)")
        
        if let trip = self.trip {
            
            print("DEBUG: HC.driverLocationUpdatedToNew: trip: \(trip)")
            
            if trip.status == .isAccepted {
                
                print("DEBUG: HC.driverLocationUpdatedToNew: distance: \(location.distance(from: trip.pickupCoordinates.location))")
                
                let isArrived = location.distance(from: trip.pickupCoordinates.location) < LocationHandler.regionRadius
                
                DispatchQueue.main.async {
                    
                    self.showDriverRouteToPickupLocation(for: trip, isArrived: isArrived)
                    self.prepareRideActionView()
                    
                }
                
            } else if trip.status == .inProgress {
                                
                DispatchQueue.main.async {
                    
                    self.progressOfUserToDestinationLocation()
                    self.prepareRideActionView()
                    
                }
                
            }
        }
            
    }
    
    /**
    
    Passenger Location updated to the new location
     
    - Parameter location: new passenger location
    
    */
    func passengerLocationUpdatedToNew(location: CLLocation) {
        
        if isDriver { return }
        
        if let trip = self.trip {
            
            if trip.status == .inProgress {
                
                
                DispatchQueue.main.async {
                    
                    self.progressOfUserToDestinationLocation()
                    self.prepareRideActionView()
                    
                }
                
            }
            
        }
        
    }
    
    func userLocationUpdated(location: CLLocation) {
        
        passengerLocationUpdatedToNew(location: location)
        
    }
    
    /**
     
     Get annotation by uid
     
     - Parameter uid: driver uid
     - Returns: **DriverAnnotation** Driver annotation object
     
     */
    
    func getAnnotationBy(uid: String) -> DriverAnnotation? {
        
        mapView.annotations.first { annotation -> Bool in
            if let annotation = annotation as? DriverAnnotation {
                return annotation.uid == uid
            } else {
                return false
            }
        } as? DriverAnnotation
    }
    
    
    /**
     
     Configure annotation for drivers
     
     - Parameter key: Geofirestore key == uid for Driver
     - Parameter location: Location of the driver
     - Parameter evet: Geofirestore event: enter / move / exit
     
     */
    
    func configureAnnotation(for key: String, and location: CLLocation, event: GFSEventType) {
        
        if tripInProgress { return }
        
        Service.shared.fetchUserData(for: key) { user in
            
            let driver = Driver(uid: user.uid, location: location, fullName: user.fullName)
            
            print("DEBUG: HC.configureAnnotation: \(driver)")
            
            let coordinate = location.coordinate
            
            
            if let annotation = self.getAnnotationBy(uid: user.uid) {
                
                UIView.animate(withDuration: 0.3) {
                    
                    let bearing = annotation.coordinate.getBearing(point: coordinate)
                    
                    print("DEBUG: HC.configureAnnotation: bearing: \(bearing)")
                    
                    annotation.coordinate = coordinate
                    annotation.bearing = bearing
                    
                    if let annotationView = self.mapView.view(for: annotation) {
                        
                        annotationView.image = annotation.image
                        
                    }
                    
                }
                
            } else {
                
                let annotation = DriverAnnotation(uid: user.uid, coordinate: coordinate, title: driver.fullName)
                
                UIView.animate(withDuration: 0.2) {
                    
                    self.mapView.addAnnotation(annotation)
                    
                }
                
            }
            
        }
    }
    
    
    
    /**
     
        Location Handler calls this method when the current user enters  pickup / destination region
     
        - Precondition: Current user must have driver account type for pickup region
     
        - Parameter region: Passenger pickup region
     
    */
    
    func didEnterRegion(_ region: CLRegion) {
        
        print("DEBUG: HC.didEnterRegion: \(region)")
        
        if region.identifier == RegionType.pickup.rid {
            
            if !isDriver { return }
            
            if let trip = self.trip {
                
                print("DEBUG: HC.didEnterRegion: driver arrived to the pickUp location")
                
                driverRoutToPickupLocation(for: trip, isArrived: true)
                
                LocationHandler.shared.log(status: .inProgress, message: nil)
                
            }
            
        } else if region.identifier == RegionType.destination.rid {
            
            if let trip = self.trip {
                
                print("DEBUG: HC.didEnterRegion: user arrived to the destination")
                
                if trip.status == .inProgress {
                    
                    LocationHandler.shared.log(status: .inProgress, message: nil)
                    
                    DispatchQueue.main.async {
                        
                        self.progressOfUserToDestinationLocation()
                        self.prepareRideActionView()
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    /**
     
        Location Handler calls this method when the current user exit  pickup / destination region
     
        - Precondition: Current user must have driver account type for pickup region
     
        - Parameter region: Passenger pickup region
     
    */
    
    func didExitRegion(_ region: CLRegion) {
        
        print("DEBUG: HC.didExitRegion: \(region)")
        
        if region.identifier == RegionType.pickup.rid {
            
            if !isDriver { return }
            
            if let trip = self.trip {
                
                print("DEBUG: HC.didExitRegion: driver leave the pickup location")
                
                driverRoutToPickupLocation(for: trip, isArrived: false)
                
                LocationHandler.shared.log(status: .inProgress, message: nil)
                
            }
            
        } else if region.identifier == RegionType.destination.rid {
            
            if let trip = self.trip {
                
                print("DEBUG: HC.didExitRegion: user leave the destination location")
                
                if trip.status == .inProgress {
                    
                    LocationHandler.shared.log(status: .inProgress, message: nil)
                    
                    DispatchQueue.main.async {
                        
                        self.progressOfUserToDestinationLocation()
                        self.prepareRideActionView()
                        
                    }
                    
                }
                
            }
            
        }
        
        
    }
    
    /**
     
     Configure trip for given pickup location that was entered / moved / exit the driver observed geo-region.
     Driver must not be busy to accept this trip
     
     - Parameter key: Trip id
     - parameter location: User pickup location
     - Parameter event: Geofirestore event type
     
    */
    func configureTrip(for key: String, and location: CLLocation, event: GFSEventType) {
        
        /*
         
            Check if key has integer value.
         
            Please note that all trips ids are random integers and passenger uids are all strings.
         
            So we would like to configure trip if and only if the key is trip id and NOT passenger uid.
         
            It's not a problem if we will try to extract a trip with the wrong key but the following
                guard statement will save us a time for database call
         
        */
        
        guard let _ = Int(key) else { return }
        
        print("DEBUG: HC.configureTrip")
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Service.shared.fetchTripData(for: key) { trip in
            
            if self.isBusy { return }
            
            if trip.status == .isRequested {
                
                print("DEBUG: HC.configureTrip: the new trip request is found!")
                
                self.trip = trip
                
                self.tripListener = Service.shared.setTripObserver(for: trip.id, self.driverTripListener)
                
            } else if trip.driverUid == uid {
                
                if trip.status == .isAccepted || trip.status == .inProgress {
                    
                    self.trip = trip
                    
                    self.tripListener = Service.shared.setTripObserver(for: trip.id, self.driverTripListener)
                    
                    print("DEBUG: HC.configureTrip: the curent trip is found! Status: \(trip.status)")
                    
                }
                
            }
            
        }
        
    }
    
    /**
     Process Geo Event for given account type
     
     - Parameter event: Geofirestore event type : Document enter / exit / moved
     - Parameter for: Account Type
     - Parameter key: Geofirestore object key
     - Parameter location: Goe event location
     
    */
    func processGeo(event: GFSEventType, for accountType: AccountType, key: String?, location: CLLocation?) {
        
        if let key = key, let location = location {
            
            print("DEBUG: HC.processGeo: event:\(event) key:\(key) location:\(location)")
            
            if accountType == .passenger {
                
                configureAnnotation(for: key, and: location, event: event)
                
            } else {
                
                configureTrip(for: key, and: location, event: event)
            }
            
            
        } else {
            print("DEBUG: HC.processGeo: Entered: No data")
        }
    }
    
    func documentEntered(for accountType: AccountType, key: String?, location: CLLocation?) {
        
        processGeo(event: .documentEntered, for: accountType, key: key, location: location)
    }
    
    func documentExited(for accountType: AccountType, key: String?, location: CLLocation?) {
        
        processGeo(event: .documentExited, for: accountType, key: key, location: location)
    }
    
    func documentMoved(for accountType: AccountType, key: String?, location: CLLocation?) {
        
        processGeo(event: .documentMoved, for: accountType, key: key, location: location)
    }
    
    
}

// MARK: - RideActionViewDelegate Protocol

extension HomeController: RideActionViewDelegate {
    
    /// End of trip. Could be activated by Driver or Passenger
    func endTrip() {
        
        print("DEBUG: HC.endTrip")
        
        guard let trip = self.trip else { return }
        guard self.user != nil else { return }
        
        Service.shared.update(trip: trip, to: .isCompleted) { result, error in
            
            if let error = error {
                
                print("DEBUG: HC.endTrip: Failed to update trip with error \(error.localizedDescription)")
                
                return
            }
            
            print("DEBUG: HC.endTrip: Trip is updated")
            
            LocationHandler.shared.log(status: .isCompleted, message: "Trip End")
            
            self.trip = nil
            self.driver = nil
            self.passenger = nil
            
            self.resetUI()
            
        }
        
    }
    
    /// Pickup the passenger and start the trip. Driver only
    func startTrip() {
        
        print("DEBUG: HC.startTrip")
        
        guard let trip = self.trip else { return }
        guard self.user != nil else { return }
        
        if !isDriver { return }
        
        Service.shared.update(trip: trip, to: .inProgress) { result, error in
            
            if let error = error {
                
                print("DEBUG: HC.startTrip: Failed to update trip with error \(error.localizedDescription)")
                
                return
            }
            
            LocationHandler.shared.log(status: .inProgress, message: "Trip Start")
            
            print("DEBUG: HC.startTrip: Trip is updated")
            
        }
        
    }
    
    
    /// Cancel Current Trip - Passenger only
    func cancelTrip() {
        
        print("DEBUG: HC.cancelTrip")
        
        guard let trip = self.trip else { return }
        guard self.user != nil else { return }
        
        if isDriver { return }
        
        Service.shared.update(trip: trip) { result, error in
            
            if let error = error {
                
                print("DEBUG: HC.cancelTrip: Failed to cancel trip with error \(error.localizedDescription)")
                
                return
            }
            
            print("DEBUG: HC.cancelTrip: Trip is canceled")
            
            self.trip = nil
            self.driver = nil
            
            self.resetUI()
            
        }
    }
    
    
    /// Upload Trip new trip by the passenger
    func uploadTrip() {
        
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
        
        guard let pickupCoordinates = locationManager?.location?.coordinate else {
            
            print("DEBUG: HC.uploadTrip: Failed to get user location")
            return
        }
        
        guard let destinationCoordinates = destinationAnnotation?.coordinate else {
            
            print("DEBUG: HC.uploadTrip: Don't have destination coordinates")
            return
            
        }
        
        let trip = Trip(destinationCoordinates: destinationCoordinates, pickupCoordinates: pickupCoordinates)
        
        shouldPresentLoadingView(true, message: "Searching for driver...")
        
        Service.shared.unloadTrip(trip: trip) { code in
            
            if code {
                
                print("DEBUG: HC.uploadTrip: Trip is uloaded")
                
                trip.setPickupLocation()
                
            } else {
                
                print("DEBUG: HC.uploadTrip: Failed to uload the trip")
                
            }
        }
    }
    
}

// MARK: - PickupController Delegate

extension HomeController: PickupControllerDelegate {
    
    /// Trip rejected delegate
    /// - Parameter trip: trejected trip
    func tripIsRejected(trip: Trip) {
        
        guard let user = self.user else { return }
        
        var rejectedTrip = trip
        
        rejectedTrip.driverUid = user.uid
        
        print("DEBUG: HC.tripIsRejected: Trip \(rejectedTrip) is rejected by Driver: \(user.fullName)")
        
        LocationHandler.shared.loggingStart(trip: rejectedTrip, status: .isCanceled)
        
        LocationHandler.shared.log(status: .isCanceled, message: "Trip is Rejected")
        
        LocationHandler.shared.loggingStop()
        
        self.trip = nil
        
    }
    
    /// Accept trip delegate
    /// - Parameter trip: accepted trip
    func tripIsAccepted(trip: Trip) {
        
        guard let user = self.user else { return }
        
        var acceptedTrip = trip
        
        acceptedTrip.driverUid = user.uid
        
        print("DEBUG: HC.tripIsAccepted: Trip \(acceptedTrip) is accepted by Driver: \(user.fullName)")
        
        LocationHandler.shared.loggingStart(trip: acceptedTrip, status: .isAccepted)
        
        LocationHandler.shared.log(status: .isAccepted, message: "Trip Accepted")
        
        
    }
    
    
}
