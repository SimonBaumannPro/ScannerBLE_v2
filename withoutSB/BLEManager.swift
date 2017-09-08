//
//  BLEHandler.swift
//  withoutSB
//
//  Created by Simon BAUMANN on 17/08/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth


protocol BLEManagerDelegate: class {
    func didStartScan(sender: BLEManager)
    func didFinishScan(sender: BLEManager)
    func refreshTableView(sender: BLEManager)
    func didDisconnect(sender: BLEManager)
    func didGetTemperature(sender: BLEManager, temp: Int)
}


class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BLEManager()
    weak var delegate : BLEManagerDelegate?
    
    var centralManager: CBCentralManager?
    var peripherals: [CBPeripheral] = []
    var connectedPeripheral: CBPeripheral?
    var services: [CBService] = []
    var tempCharasteristic: CBCharacteristic?
    var ledCharasteristic: CBCharacteristic?
    var ledIsOn = false
    
    // value send to the peripheral to put the blueled on/off
    let dataBlueLedOn: [UInt8] = [0xFF]
    let dataBlueLedOff: [UInt8] = [0x00]
    
    
    override private init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        print("[log] - centralManager Initialized")
    }
    
    /* Start the BLE peripherals scan */
    func startScanning() {
        let triggerTime = (Int64(NSEC_PER_SEC)*5) // Nanosec per sec
        
        peripherals = []    // Init the peripheral array before each scan
        
        delegate?.didStartScan(sender: self) // Update the title of the navigation controller
        
        // Scan devices and add them to the tableView
        self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        print("[log] - Scanning...")
        
        // Interrupt the scan and update the view after a time deadline
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime)/Double(NSEC_PER_SEC), execute: { () -> Void in
            if (self.centralManager!.isScanning) {
                self.stopScanning()
            }
        })
    }
    
    /* Stop the BLE peripheral Scan */
    func stopScanning () {
        centralManager?.stopScan()
        delegate?.didFinishScan(sender: self)
        print("[log] - Scan stopped")
    }
    
    func switchLight() {
        let data: Data
        if ledIsOn {
            data = Data(bytes: dataBlueLedOff)
            ledIsOn = false
        } else {
            data = Data(bytes: dataBlueLedOn)
            ledIsOn = true
        }
        connectedPeripheral?.writeValue(data, for: ledCharasteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    // put the light off at the initialisation
    func initBlueLight() {
        let data = Data(bytes: dataBlueLedOff)
        connectedPeripheral?.writeValue(data, for: ledCharasteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func disconnectPeripheral() {
        centralManager?.cancelPeripheralConnection(connectedPeripheral!)
    }
    
    
    /* Get the state of the centralManager over the time */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn) {
            print("[log] - Central Manager state = PoweredOn")
            startScanning()
        } else {
            print("[log] - Central Manager state = BLE ERROR")
            print("[log] - Bluetooth needs to be activated")
        }
    }
    
    /* The centralManager has discovered a (new?) BLE peripheral */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let peripheralName = peripheral.name
        
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        if peripheralName != nil {
            if (peripheralName?.contains("test"))! {
                if (isConnectable && !peripherals.contains(peripheral)) {
                    print("peripheral discovered : \(String(describing: peripheralName))")
                    peripherals.append(peripheral)
                    delegate?.refreshTableView(sender: self)
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[log] - Peripheral connected")
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("peripheral disconnected")
        delegate?.didDisconnect(sender: self)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
        if error != nil {
            print("Error discovering services: \(String(describing: error?.localizedDescription))")
        }
        
        peripheral.services?.forEach({ (service) in
            peripheral.discoverCharacteristics(nil, for: service)
            services.append(service)
        })
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor : \(service.uuid.uuidString)")
        if error != nil {
            print("Error discovering service characteristics: \(String(describing: error?.localizedDescription))")
        }
        
        service.characteristics?.forEach({(characteristic) in
            if characteristic.properties.contains(CBCharacteristicProperties.write) {
                ledCharasteristic = characteristic
            } else if characteristic.properties.contains(CBCharacteristicProperties.read) {
                tempCharasteristic = characteristic
            }
        })
        if tempCharasteristic != nil {
            peripheral.readValue(for: tempCharasteristic!)
        } else {
            delegate?.didGetTemperature(sender: self, temp: Int(0))
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didDUpdateValueFor: \(characteristic)")
        if let error = error {
            print("Failed… error:  \(error)")
            return
        }
        let temp: UInt8
        
        /* When the LoRa kit is plug, CharacteristicTemp has no value
         when you connect for the first time. TODO: Solve the issue. */
        if characteristic.value?.count == 0 {
            temp = 0
        } else {
            temp = (characteristic.value?[0])!
        }
        delegate?.didGetTemperature(sender: self, temp: Int(temp))
    }
}
