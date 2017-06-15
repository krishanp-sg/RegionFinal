//
//  UploadLocations.swift
//  RegionFinal
//
//  Created by Krishan Sunil Premaretna on 14/6/17.
//  Copyright © 2017 Krishan Sunil Premaretna. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class UploadLocations: NSObject {
    
    static let sharedLocation = UploadLocations()
    var isUploadingDataToServer : Bool = false
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    

    
    func sendLocationBackToServer() {
        
        
        self.isUploadingDataToServer = true
        
        registerBackgroundTask()
        
        
        // retrive locations to send
        LocationDataAccess.retriveUserLocation({ userLocationsToSend in
            
            if userLocationsToSend?.count == 0 {
                
                if self.backgroundTask != UIBackgroundTaskInvalid {
                    self.endBackgroundTask()
                }
                
                self.isUploadingDataToServer = false
                return
            }
            
            let exportService = ExportLocations.sharedInstance
            exportService.uploadDataToServer(userLocationsToSend!, succesHandler: { userLocations in
                
                LocationDataAccess.deleteTransferedUserLocations(userLocations)
                
                KeychainWrapper.standard.set(Date.timeIntervalSinceReferenceDate, forKey: "lastUpdatedTime")
                
                self.isUploadingDataToServer = false
                if self.backgroundTask != UIBackgroundTaskInvalid {
                    self.endBackgroundTask()
                }
                
            }, failureHandler: { errorMessage in
                
                self.isUploadingDataToServer = false

                if self.backgroundTask != UIBackgroundTaskInvalid {
                    self.endBackgroundTask()
                }
                
            })
            
        })
        
    }


}
