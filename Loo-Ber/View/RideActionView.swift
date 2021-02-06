//
//  RideActionView.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit

//MARK: - RideActionViewDelegate Protocol

protocol RideActionViewDelegate: class {
    
    /**
     Upload new trip request
     */
    func uploadTrip()
    
    /**
     Cancel trip by passenger
     */
    func cancelTrip()
    
    /**
     Start trip by Driver
     */
    func startTrip()
    
    /**
     End trip by User
     */
    func endTrip()
    
}

//MARK: - RideActionViewConfiguration Enum

typealias ConfigParameters = (AccountType, String, String)

enum RideActionViewConfiguration {
    case requestRide(ConfigParameters)
    case tripAccepted(ConfigParameters)
    case driverArrived(ConfigParameters)
    case pickupPassenger(ConfigParameters)
    case tripInProgress(ConfigParameters)
    case endTrip(ConfigParameters)
    
    init() {
        self = .requestRide((.passenger, "Test Drive Title", "Address Drive test address"))
    }
}
//MARK: - ButtonAction Enum
enum ButtonAction: CustomStringConvertible {
    case requestRide
    case cancel
    case getDirections
    case pickup
    case dropOff
    case endTrip
    
    var description: String {
        switch self {
        case .requestRide: return "CONFIRM LOOBER"
        case .cancel: return "CANCEL RIDE"
        case .getDirections: return "GET DIRECTIONS"
        case .pickup: return "PICKUP PASSENGER"
        case .dropOff: return "DROP OFF PASSENGER"
        case .endTrip: return "END OF TRIP"
        }
    }
    
    init() {
        self = .requestRide
    }
}


//MARK: - RideActionView Class

class RideActionView: UIView {
    
    //MARK: - Properties
    
    weak var delegate: RideActionViewDelegate?
    
    var config = RideActionViewConfiguration()
    var buttonAction = ButtonAction()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "Test Drive Title"
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = "Address Drive test address"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var infoView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundColor
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30)
        label.textColor = .white
        view.addSubview(label)
        label.centerX(inView: view)
        label.centerY(inView: view)
        return view
    }()
    
    private let uberTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "LooBer"
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .backgroundColor
        button.setTitle("CONFIRM LOOBER", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
        
    }()
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        addShadow()
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.distribution = .fillEqually
        
        addSubview(stack)
        stack.centerX(inView: self)
        stack.anchor(top: topAnchor, paddingTop: 12)
        
        addSubview(infoView)
        infoView.centerX(inView: self)
        infoView.anchor(top: stack.bottomAnchor, paddingTop: 16)
        infoView.setDimension(height: 80, width: 80)
        infoView.layer.cornerRadius = 80/2
        infoView.backgroundColor = .backgroundColor
        
        addSubview(uberTypeLabel)
        uberTypeLabel.centerX(inView: self)
        uberTypeLabel.anchor(top: infoView.bottomAnchor, paddingTop: 8)
        
        addSubview(separatorView)
        separatorView.anchor(top: uberTypeLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 10, height: 0.75)
        
        addSubview(actionButton)
        actionButton.anchor(top: separatorView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 20, paddingLeft: 12, paddingRight: 12, height: 50)
    
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Selectors
    
    @objc func actionButtonPressed() {
        
        print("DEBUG: Action Drive Button is pressed!")
        
        switch buttonAction {

        case .requestRide: delegate?.uploadTrip()
            
        case .cancel: delegate?.cancelTrip()
            
        case .getDirections: print("DEBUG: Direction is requested")
            
        case .pickup: delegate?.startTrip()
            
        case .dropOff: delegate?.endTrip()
            
        case .endTrip: delegate?.endTrip()
        
        }
        
    }
    
    //MARK: - Helpers
    
    func setInfoLabel(text: String) {
        
        if let label = infoView.subviews.first as? UILabel {
            
            label.text = text
            
        }
    }
    
    func adjustAddress(_ address: String) -> String {
        
        address.count < 40 ? address : "\(address.prefix(40)) ..."
        
    }
    
    func setLabelText(title: String, address: String, info: String? = nil, type: String? = nil) {
    
        
        titleLabel.text = title
        
        addressLabel.text = adjustAddress(address)
        
        setInfoLabel(text: info ?? "L")
        
        uberTypeLabel.text = type ?? "LooBer"
        
    }
    
    func setButton(action: ButtonAction) {
        
        buttonAction = action
        
        actionButton.setTitle(action.description, for: .normal)
        
    }
    
    func configureUI(withConfig config: RideActionViewConfiguration) {
        
        switch config {
        
        case .requestRide(_, let title, let address):
            
            setLabelText(title: title, address: address)
            setButton(action: .requestRide)
            
        case .tripAccepted(let act, let address, let name):
            
            if act == .driver {
                
                let sign = "\(name.first  ?? "L")"
                setLabelText(title: "En Route To Passenger", address: address, info: sign, type: name)
                setButton(action: .getDirections)
                
            } else {
                
                let sign = "\(name.first  ?? "L")"
                setLabelText(title: "Driver En Route", address: address, info: sign, type: name)
                setButton(action: .cancel)
            }
            
        case .driverArrived(_, _, let name):
            
            let sign = "\(name.first  ?? "L")"
            setLabelText(title: "Driver Has Arrived", address: "Please meet driver at pickup location", info: sign, type: name)
            setButton(action: .cancel)
            
        case .pickupPassenger(_, let address, let name):
            
            let sign = "\(name.first  ?? "L")"
            setLabelText(title: "Arrived At Passenger Location", address: address, info: sign, type: name)
            setButton(action: .pickup)
            
        case .tripInProgress(_, let address, let name):
           
            let sign = "\(name.first  ?? "L")"
            setLabelText(title: "Trip in Progress", address: address, info: sign, type: name)
            setButton(action: .getDirections)
                
            
        case .endTrip(let act, let address, let name):
            
            if act == .driver {
                
                let sign = "\(name.first  ?? "L")"
                setLabelText(title: "Arrived at distination", address: address, info: sign, type: name)
                setButton(action: .dropOff)
            
            } else {
                
                let sign = "\(name.first  ?? "L")"
                setLabelText(title: "Arrived at distination", address: address, info: sign, type: name)
                setButton(action: .endTrip)
                
            }

        }
    }
}
