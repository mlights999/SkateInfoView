//
//  ParticlePerihperal.swift
//  SmartIO
//
//  Created by Matthew Panizza on 3/1/20.
//  Copyright © 2020 Matthew Panizza. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol ParticleDelegate {
    
}

class ParticlePeripheral: NSObject {
    
    /// MARK: - Particle LED services and charcteristics Identifiers
    
    public static let SkateInfoServiceUUID             = CBUUID.init(string: "b4250400-fb4b-4746-b2b0-93f0e61122c6")
    public static let rpmCharacteristicUUID          = CBUUID.init(string: "b4250401-fb4b-4746-b2b0-93f0e61122c6")
    public static let CloudCharacteristicUUID          = CBUUID.init(string: "b4250402-fb4b-4746-b2b0-93f0e61122c6")
    public static let bttlvlCharacteristicUUID         = CBUUID.init(string: "b4250403-fb4b-4746-b2b0-93f0e61122c6")
    public static let currlvlCharacteristicUUID        = CBUUID.init(string: "b4250404-fb4b-4746-b2b0-93f0e61122c6")
    public static let estpctCharacteristicUUID         = CBUUID.init(string: "b4250405-fb4b-4746-b2b0-93f0e61122c6")
    public static let enconsCharacteristicUUID         = CBUUID.init(string: "b4250406-fb4b-4746-b2b0-93f0e61122c6")
    public static let tempCharacteristicUUID         = CBUUID.init(string: "b4250407-fb4b-4746-b2b0-93f0e61122c6")
    public static let odoCharacteristicUUID         = CBUUID.init(string: "b4250408-fb4b-4746-b2b0-93f0e61122c6")
    
    /*public static let batteryCharacteristicUUID  = CBUUID.init(string: "2a19")*/
    
    /**/
    
}
