//
//  LocationInputCell.swift
//  Loo-Ber
//
//  Created by Emmanuel Mawuli Klutse on 4/25/20.
//  Copyright © 2020 Emmanuel Klutse. All rights reserved.
//

import UIKit

class LocationInputCell: UITableViewCell {

    //MARK: - Properties
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "123 Main St"
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.text = "123 Main St, Washington, DC"
        return label
    }()
    
    //MARK: - Lifecycle
    
    func configureCell(title: String, address: String) {
        
        titleLabel.text = title
        addressLabel.text = address
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, addressLabel])
        stack.distribution = .fillEqually
        stack.axis = .vertical
        stack.spacing = 4
        
        addSubview(stack)
        stack.centerY(inView: self, left: leftAnchor, paddingLeft: 8)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
