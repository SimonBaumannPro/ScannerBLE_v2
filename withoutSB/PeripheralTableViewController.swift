//
//  ViewController.swift
//  withoutSB
//
//  Created by Simon BAUMANN on 16/08/2017.
//  Copyright © 2017 Simon BAUMANN. All rights reserved.
//

import UIKit
import CoreBluetooth


class PeripheralTableViewController: UITableViewController, BLEManagerDelegate {

    let detailsVC = DetailsViewController()
    let subView = UIView()
    let bleIcon = UIImage(named: "bt-icon")
    let alertConnection = UIAlertController(title: nil, message: " Connection...", preferredStyle: .alert)
    let alertUnableToConnect = UIAlertController(title: "Failed to connect", message: "Try again ?!", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {(result : UIAlertAction) -> Void in }
    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
    let scanningLabel = "Scanning ..."
    
    var button : UIButton?
    var tempOfPeripheralConnected: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BLEManager.shared.delegate = self
        
        refreshControl = UIRefreshControl()
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl!)
        }
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        alertConnection.view.addSubview(loadingIndicator)
        alertUnableToConnect.addAction(okAction)
        
        refreshControl?.addTarget(self, action: #selector(refreshTableviewAfterPullDown(sender:)), for: .valueChanged)
        refreshControl?.attributedTitle = NSAttributedString(string: "Refresh peripheral list")
        
        navigationItem.title = "Scanning ..."
        
        tableView.register(PeripheralTableViewCell.self, forCellReuseIdentifier: "cellId")
        tableView.register(PeripheralTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "headerId")
        tableView.sectionHeaderHeight = 50
        tableView.tableFooterView = UIView()
        
        view.backgroundColor = UIColor.white
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLEManager.shared.peripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as! PeripheralTableViewCell
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        cell.peripheral = BLEManager.shared.peripherals[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "headerId")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let periphSelected = BLEManager.shared.peripherals[indexPath.row]
        let triggerTime = (Int64(NSEC_PER_SEC)*5) // Nanosec per sec
        BLEManager.shared.centralManager?.connect(periphSelected, options: nil)
        loadingIndicator.startAnimating();
        present(alertConnection, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime)/Double(NSEC_PER_SEC), execute: { () -> Void in
            if (periphSelected.state != .connected) {
                self.alertConnection.dismiss(animated: true, completion: {
                    self.present(self.alertUnableToConnect, animated: true, completion: nil)
                    tableView.deselectRow(at: indexPath, animated: true)
                    BLEManager.shared.startScanning()
                })
            }
        })
    }
    
    
    func refreshTableviewAfterPullDown(sender: Any) {
        BLEManager.shared.startScanning()
    }
    
    func refreshTableView(sender: BLEManager) {
        tableView.reloadData()
    }
    
    func didStartScan(sender: BLEManager) {
        if navigationItem.title != scanningLabel { navigationItem.title = scanningLabel }
    }
    
    func didFinishScan(sender: BLEManager) {
        navigationItem.title = "Scan stopped"
        refreshControl?.endRefreshing()
    }
    
    func didDisconnect(sender: BLEManager) {
        BLEManager.shared.peripherals.removeAll()
        _ = navigationController?.popToRootViewController(animated: true)
        tableView.reloadData()
        BLEManager.shared.startScanning()
    }
    
    func didGetTemperature(sender: BLEManager, temp: Int) {
        tempOfPeripheralConnected = temp
        detailsVC.temperature = temp
        detailsVC.deviceName = BLEManager.shared.connectedPeripheral?.name
        self.alertConnection.dismiss(animated: false, completion: {() -> Void in
            self.navigationController?.pushViewController(self.detailsVC, animated: true)
        })
    }
}
