//
//  InterfaceController.swift
//  SKInfo WatchKit Extension
//
//  Created by Matthew on 12/27/20.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {

    @IBOutlet var voltageLabel: WKInterfaceLabel!
    @IBOutlet var currentLabel: WKInterfaceLabel!
    @IBOutlet var percentLabel: WKInterfaceLabel!
    @IBOutlet var energyLabel: WKInterfaceLabel!
    @IBOutlet var temperatureLabel: WKInterfaceLabel!
    @IBOutlet weak var SpeedLabel: WKInterfaceLabel!
    
    let session = WCSession.default//**3
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        session.delegate = self//**4
        session.activate()//**5
      }
      
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
      }
      
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        //phoneStatus.setHidden(false)
      }

}
extension InterfaceController: WCSessionDelegate {
  
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    
  }
    
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    //phoneStatus.setHidden(true)
    print("received data: \(message)")
    if let value = message["Current"] as? String {//**7.1
        self.currentLabel.setText(value)
    }
    if let value = message["Voltage"] as? String {//**7.1
        self.voltageLabel.setText(value)
    }
    if let value = message["Percent"] as? String {//**7.1
        self.percentLabel.setText(value)
    }
    if let value = message["Energy"] as? String {//**7.1
        self.energyLabel.setText(value)
    }
    if let value = message["Temperature"] as? String {//**7.1
        self.temperatureLabel.setText(value)
    }
    if let value = message["Speed"] as? String {//**7.1
        self.SpeedLabel.setText(value)
    }
  }
}

