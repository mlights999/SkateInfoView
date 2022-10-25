//
//  ViewController.swift
//  SKInfo
//
//  Created by Matthew on 12/27/20.
//

import UIKit
import WatchConnectivity
import CoreBluetooth


class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {

    @IBOutlet weak var rcConnected: UIImageView!
    @IBOutlet weak var awConnected: UIImageView!
    @IBOutlet weak var rcNotConnected: UIImageView!
    @IBOutlet weak var awNotConnected: UIImageView!
    @IBOutlet weak var percentProgress: UIProgressView!
    @IBOutlet weak var percentLabel: UILabel!
    @IBOutlet weak var voltageLabel: UILabel!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var energyLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var devVoltageChar: UILabel!
    @IBOutlet weak var devCurrentChar: UILabel!
    @IBOutlet weak var cloudConnect: UIButton!
    @IBOutlet weak var MeshConnect: UIButton!
    @IBOutlet weak var BatteryButton: UIButton!
    @IBOutlet weak var dfuMode: UIButton!
    @IBOutlet weak var nameTag: UILabel!
    @IBOutlet weak var RPMLabel: UILabel!
    @IBOutlet weak var SpeedLabel: UILabel!
    @IBOutlet weak var OdoLabel: UILabel!
    
    private var currentChar: CBCharacteristic?
    private var voltageChar: CBCharacteristic?
    private var percentChar: CBCharacteristic?
    private var energyChar: CBCharacteristic?
    private var modeChar: CBCharacteristic?
    private var tempChar: CBCharacteristic?
    private var rpmChar: CBCharacteristic?
    private var odoChar: CBCharacteristic?
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    
    var discoveredDevices = Set<CBPeripheral>()
    
    var session: WCSession?  //Name watch session as "session" for shorter calls
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureWatchKitSesstion()//4
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func configureWatchKitSesstion() {
        
        if WCSession.isSupported() {//4.1
          session = WCSession.default//4.2
          session?.delegate = self//4.3
          session?.activate()//4.4
        }
    }
    
    @IBAction func devSliderChanged(_ sender: Any) {
        devVoltageChar.isHidden = false
        devCurrentChar.isHidden = false
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for", ParticlePeripheral.SkateInfoServiceUUID);
            centralManager.scanForPeripherals(withServices: [ParticlePeripheral.SkateInfoServiceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    // Handles the result of the scan
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredDevices.insert(peripheral)
        let tempPeripheral = discoveredDevices.popFirst()
        
        // We've found it so stop scan
        self.centralManager.stopScan()
        //isScanning.stopAnimating()
        // Copy the peripheral instance
        self.peripheral = tempPeripheral//peripheral
        self.peripheral.delegate = self
        
        // Connect!
        self.centralManager.connect(self.peripheral, options: nil)
        
    }
    
    // The handler if we do connect succesfully
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            nameTag.text = peripheral.name
            print(peripheral.name ?? "Unknown")
            print("Connected to your Particle Board")
            peripheral.discoverServices([ParticlePeripheral.SkateInfoServiceUUID]);
        }
        rcNotConnected.isHidden = true;
        rcConnected.isHidden = false;
    }
    //Disconnect Event
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            print("Disconnected")
            self.peripheral = nil
            
            // Start scanning again
             print("Central scanning for", ParticlePeripheral.SkateInfoServiceUUID);
             centralManager.scanForPeripherals(withServices: [ParticlePeripheral.SkateInfoServiceUUID],
             options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == ParticlePeripheral.SkateInfoServiceUUID {
                    print("LED service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics([ParticlePeripheral.CloudCharacteristicUUID,ParticlePeripheral.bttlvlCharacteristicUUID, ParticlePeripheral.currlvlCharacteristicUUID, ParticlePeripheral.estpctCharacteristicUUID,ParticlePeripheral.enconsCharacteristicUUID,ParticlePeripheral.tempCharacteristicUUID,ParticlePeripheral.rpmCharacteristicUUID,ParticlePeripheral.odoCharacteristicUUID], for: service)
                }
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral,
                         didUpdateNotificationStateFor characteristic: CBCharacteristic,
                         error: Error?) {
            print("Enabling notify ", characteristic.uuid)
            
        if error != nil {
            print("Enable notify error")
        }
    }

    
    
    // Handling discovery of characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                 if characteristic.uuid == ParticlePeripheral.CloudCharacteristicUUID {
                    print("Green LED characteristic found")
                        
                        // Set the characteristic
                        modeChar = characteristic
                        cloudConnect.isEnabled = true
                        dfuMode.isEnabled = true
                        MeshConnect.isEnabled = true
                        BatteryButton.isEnabled = true

                    
                } else if characteristic.uuid == ParticlePeripheral.bttlvlCharacteristicUUID {
                    print("Battery characteristic found");
                        
                    // Set the char
                    voltageChar = characteristic
                    // Subscribe to the char.
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if characteristic.uuid == ParticlePeripheral.currlvlCharacteristicUUID {
                        print("Current characteristic found");
                        
                        // Set the char
                        currentChar = characteristic
                        
                        // Subscribe to the char.
                        peripheral.setNotifyValue(true, for: characteristic)
                }
                else if characteristic.uuid == ParticlePeripheral.estpctCharacteristicUUID {
                    print("Current characteristic found");
                        
                    // Set the char
                    percentChar = characteristic
                        
                    // Subscribe to the char.
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                else if characteristic.uuid == ParticlePeripheral.enconsCharacteristicUUID {
                    print("Current characteristic found");
                        
                    // Set the char
                    energyChar = characteristic
                        
                    // Subscribe to the char.
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                else if characteristic.uuid == ParticlePeripheral.tempCharacteristicUUID {
                    print("Temperature characteristic found");
                        
                    // Set the char
                    tempChar = characteristic
                        
                    // Subscribe to the char.
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                else if characteristic.uuid == ParticlePeripheral.rpmCharacteristicUUID {
                    print("RPM characteristic found");
                        
                    // Set the char
                    rpmChar = characteristic
                        
                    // Subscribe to the char.
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                else if characteristic.uuid == ParticlePeripheral.odoCharacteristicUUID {
                    print("RPM characteristic found");
                        
                    // Set the char
                    odoChar = characteristic
                        
                    // Subscribe to the char.
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    private func writeToChar( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        
        // Check if it has the write property
        if characteristic.properties.contains(.writeWithoutResponse) && peripheral != nil {
            
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
            
        }
        
    }
    @IBAction func cloudButton(_ sender: Any) {
        let slider:UInt8 = UInt8(1)
        writeToChar( withCharacteristic: modeChar!, withValue: Data([slider]))
    }
    @IBAction func DFUButton(_ sender: Any) {
        let slider:UInt8 = UInt8(2)
        writeToChar( withCharacteristic: modeChar!, withValue: Data([slider]))
    }
    @IBAction func MeshButton(_ sender: Any) {
        let slider:UInt8 = UInt8(3)
        writeToChar( withCharacteristic: modeChar!, withValue: Data([slider]))
    }
    @IBAction func BatteryButton(_ sender: Any) {
        let slider:UInt8 = UInt8(4)
        writeToChar( withCharacteristic: modeChar!, withValue: Data([slider]))
    }
    
    func peripheral(_ peripheral: CBPeripheral,didUpdateValueFor characteristic: CBCharacteristic,error: Error?) {
        if( characteristic == currentChar ) {
            print("current:", characteristic.value![0])
            let testVal: Int32 = Int32(characteristic.value![0])+256*Int32(characteristic.value![1])-4096;
            //let currVal: Double =  0.008*Double(testVal)
            currentLabel.text = String(format: "%.2f A", 0.008*Double(testVal))
            devCurrentChar.text = "\(testVal)"
            if let validSession = self.session, validSession.isReachable {//5.1
                let data: [String: Any] = ["Current": String(format: "Current           %.2f A", 0.008*Double(testVal)) as Any] // Create your Dictionay as per uses
                validSession.sendMessage(data, replyHandler: nil, errorHandler: nil)
            }
        }
        if( characteristic == voltageChar ) {
            print("Battery:", characteristic.value![0])
            let testVal: Int16 = Int16(characteristic.value![0])+256*Int16(characteristic.value![1]);
            let dataStr = String(format: "%.2f V", Double(testVal)/79.125);
            voltageLabel.text = dataStr
            devVoltageChar.text = "\(testVal)"
            if let validSession = self.session, validSession.isReachable {//5.1
                let data: [String: Any] = ["Voltage": String(format: "Voltage          %.2f V", Double(testVal)/79.125) as Any] // Create your Dictionay as per uses
                validSession.sendMessage(data, replyHandler: nil, errorHandler: nil)
                awNotConnected.isHidden = true;
                awConnected.isHidden = false;
            }
            else{
                awNotConnected.isHidden = false;
                awConnected.isHidden = true;
            }
        }
        if( characteristic == percentChar ) {
            print("percent:", characteristic.value![0])
            let currVal: Double = Double(characteristic.value![0]);
            percentLabel.text = "\(currVal)%"
            percentProgress.progress = Float(currVal/100);
            if let validSession = self.session, validSession.isReachable {//5.1
                let data: [String: Any] = ["Percent": "\(currVal) %" as Any] // Create your Dictionay as per uses
                validSession.sendMessage(data, replyHandler: nil, errorHandler: nil)
            }
        }
        if( characteristic == energyChar ) {
            print("energy:", characteristic.value![0])
            let energyVal: Int32 = Int32(characteristic.value![0])+256*Int32(characteristic.value![1]);
            energyLabel.text = "\(energyVal)mAh"
            if let validSession = self.session, validSession.isReachable {//5.1
                let data: [String: Any] = ["Energy": "Energy        \(energyVal)mAh" as Any] // Create your Dictionay as per uses
                validSession.sendMessage(data, replyHandler: nil, errorHandler: nil)
            }
        }
        if( characteristic == tempChar ) {
            print("energy:", characteristic.value![0])
            let energyVal: Int32 = Int32(characteristic.value![0])+256*Int32(characteristic.value![1]);
            let tempval: Double = Double(energyVal)/Double(100);
            temperatureLabel.text = "\(tempval) F"
            if let validSession = self.session, validSession.isReachable {//5.1
                let data: [String: Any] = ["Temperature": "Temperature        \(tempval) F" as Any] // Create your Dictionay as per uses
                validSession.sendMessage(data, replyHandler: nil, errorHandler: nil)
            }
        }
        if( characteristic == rpmChar ) {
            print("rpm:", characteristic.value![0])
            let rpmVal: Int32 = 60*Int32(characteristic.value![0]);
            let speedVal: Double = Double(characteristic.value![0])*Double(0.6322);
            RPMLabel.text = "\(rpmVal) RPM"
            SpeedLabel.text = "\(speedVal) MPH"
            if let validSession = self.session, validSession.isReachable {//5.1
                let data: [String: Any] = ["Speed": "\(speedVal) MPH" as Any] // Create your Dictionay as per uses
                validSession.sendMessage(data, replyHandler: nil, errorHandler: nil)
            }
        }
        if( characteristic == odoChar ) {
            //print("Odometer:", characteristic.value![0])
            let testVal: Int32 = Int32(characteristic.value![0])+256*Int32(characteristic.value![1])+65536*Int32(characteristic.value![2]);
            let dataStr = String(format: "Trip: %.2f Mi", Double(testVal)/100.0);
            OdoLabel.text = dataStr;
            if let validSession = self.session, validSession.isReachable {//5.1
                let data: [String: Any] = ["Distance": String(format: "Distance        %.2f Mi", Double(testVal)/100.0) as Any] // Create your Dictionay as per uses
                validSession.sendMessage(data, replyHandler: nil, errorHandler: nil)
            }
        }
    }
}

extension ViewController: WCSessionDelegate {
  
  func sessionDidBecomeInactive(_ session: WCSession) {
  }
  
  func sessionDidDeactivate(_ session: WCSession) {
    
  }
  
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    //awNotConnected.isHidden = true;
    //awConnected.isHidden = false;
  }
  
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    
  }
}

