//
//  SecondViewController.swift
//  withoutSB
//
//  Created by Simon BAUMANN on 16/08/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth

class DetailsViewController: UIViewController {
    
    let tempLabel = UILabel(frame: CGRect(x: 100, y: 100, width: 150, height: 150))
    let ledButton = UIButton(type: UIButtonType.custom) as UIButton
    let lightIcon = UIImage(named: "light-icon") as UIImage?
    let peripheral : CBPeripheral? = nil
    var i = 0   // temperature counter indicator
    var ledOn = false   // led value indicator
    var deviceName : String? = nil
    var timer: Timer? = nil
    var temperature = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        self.tempLabel.textColor = UIColor.black
        self.view.backgroundColor = UIColor.white
        self.tempLabel.backgroundColor = UIColor.orange
        
        view.addSubview(tempLabel)
        view.addSubview(ledButton)
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        BLEManager.shared.initBlueLight()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Disconnect", comment: "Disconnect"), style: .plain, target: self, action:#selector(self.backToRootVC))
        tempLabel.text = " 0°"
        self.navigationItem.title = deviceName
        self.ledButton.backgroundColor = UIColor.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let tempString = String(format: "%X", temperature)
        let tempInt : Int = NSString(string: tempString).integerValue
        
        timer =  Timer.scheduledTimer(timeInterval: 0.05, target: self, selector:#selector(DetailsViewController.printTemperature), userInfo: tempInt, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        BLEManager.shared.disconnectPeripheral()
        tempLabel.text = " 0°"
    }
    
    func setupView() {
        
        tempLabel.text = " 0°"
        tempLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 50)
        tempLabel.layer.masksToBounds = true
        tempLabel.textAlignment = NSTextAlignment.center
        tempLabel.layer.cornerRadius = tempLabel.frame.width/2
        tempLabel.center.x = view.frame.width/2
        tempLabel.center.y = view.frame.height/3
        
        ledButton.frame = CGRect(x: view.frame.width/2 - 62, y: view.frame.height/2 + 90, width: 125, height: 125)
        ledButton.layer.masksToBounds = true
        ledButton.layer.cornerRadius = ledButton.frame.width/2
        ledButton.setBackgroundImage(lightIcon, for: .normal)
        ledButton.addTarget(self, action: #selector(DetailsViewController.lightButtonTapped(_:)), for: .touchUpInside)
    }

    // switch the light value of the peripheral connected
    func lightButtonTapped(_ sender: UIButton!) {
        BLEManager.shared.switchLight()
        if ledOn == false {
            ledOn = true
            UIView.animate(withDuration: 1.5) {
                self.ledButton.backgroundColor = UIColor(red: 0, green: 0.7686, blue: 0.8863, alpha: 1.0)
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.ledButton.backgroundColor = UIColor.white
            }
            ledOn = false
        }
    }
    
    func printTemperature() {
        let tempString = String(format: "%d", i)
        let tempInt = timer?.userInfo as! Int
        tempLabel.text = " ".appending(tempString.appending("°"))
        i += 1
        
        if i > tempInt {
            i = 0
            timer?.invalidate()
        }
    }
    
    // go back to the root view controller
    func backToRootVC() {
        self.dismiss(animated: false, completion: nil)
        _ = navigationController?.popViewController(animated: true)
    }
}
