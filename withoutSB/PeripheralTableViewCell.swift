//
//  PeripheralTableViewCell.swift
//  withoutSB
//
//  Created by Simon BAUMANN on 21/08/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralTableViewCell: UITableViewCell {
    
    var peripheral:CBPeripheral? {
        didSet {
            self.peripheralName.text = peripheral?.name
        }
    }
    
    var peripheralName: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    func setupViews() {
        addSubview(peripheralName)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-16-[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": peripheralName]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v0]|", options: NSLayoutFormatOptions(), metrics: nil, views: ["v0": peripheralName]))
    }
}
