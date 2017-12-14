//
//  Network.swift
//  DemoHW
//
//  Created by NguyenVuHuy on 12/11/17.
//  Copyright © 2017 Hyubyn. All rights reserved.
//

import Foundation

import SystemConfiguration.CaptiveNetwork

class NetworkChecker : NSObject {
    
    func getSSID() -> String? {
        
        let interfaces = CNCopySupportedInterfaces()
        if interfaces == nil {
            return nil
        }
        
        let interfacesArray = interfaces as! [String]
        if interfacesArray.count <= 0 {
            return nil
        }
        
        let interfaceName = interfacesArray[0] as String
        let unsafeInterfaceData =     CNCopyCurrentNetworkInfo(interfaceName as CFString)
        if unsafeInterfaceData == nil {
            return nil
        }
        
        let interfaceData = unsafeInterfaceData as! Dictionary <String,AnyObject>
        
        return interfaceData["SSID"] as? String
    }
    
}
