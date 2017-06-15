//
//  LocationManager.swift
//  RegionFinal
//
//  Created by Krishan Sunil Premaretna on 22/5/17.
//  Copyright © 2017 Krishan Sunil Premaretna. All rights reserved.
//

import UIKit
import CoreLocation

class LocationManager: NSObject {
    
    let distanceFilter = 50.0
    
    static let sharedManager = LocationManager()
    var locationManager : CLLocationManager?
    var isAppInforeground : Bool = false
    var locationShareModel = LocationShareModel.sharedInstance
    var isAppLaunchedFromLocationKey = false
    var isUserInIdleState = false
    var isUserIdleRegionToMonitorCreated = false
    
    
    var userLastLocation : CLLocation?
    
    func setupLocationManager(){
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager!.allowsBackgroundLocationUpdates = true
        self.locationManager?.requestAlwaysAuthorization()
        self.locationManager?.startUpdatingLocation()
        
        stopDynamicRegions()
    }
    
    required override init(){
        
        super.init()
        // register for App Will Enter Background and App Will  Enter Forground Notification
        
        let notificationCenter = NotificationCenter.default
        
        // App will Enter Background
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        // App Will Enter Foreground
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

        
         notificationCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
         self.locationShareModel.bagTaskManager = BackgroundTaskManager.shared()
         self.locationShareModel.bagTaskManager!.delegate = self
    }
    
    func stopTimers(){
        
        if self.locationShareModel.backgroundTimer != nil {
            self.locationShareModel.backgroundTimer?.invalidate()
            self.locationShareModel.backgroundTimer = nil
        }
        
        if self.locationShareModel.stopLocationManagerAfter10sTimer != nil {
            self.locationShareModel.stopLocationManagerAfter10sTimer?.invalidate()
            self.locationShareModel.stopLocationManagerAfter10sTimer = nil
        }
    }
    
    
    
    func appMovedToBackground(){
        isAppInforeground = false
        CommonHelper.writeToFile("App Moved To Background ")
       
        self.locationShareModel.bagTaskManager?.beginNewBackgroundTask()
        self.locationManager!.stopUpdatingLocation()
        self.locationManager?.startUpdatingLocation()
    }
    
    func appMovedToForeground(){
        isAppInforeground = true
        CommonHelper.writeToFile("App Moved To Foreground ")
        stopDynamicRegions()
        stopTimers()
        self.locationManager!.startUpdatingLocation()
    }
    
    func appDidBecomeActive(){
        isAppInforeground = true
        CommonHelper.writeToFile("App Did Become Active ")
    }
    
    func restartLocationUpdate(){
        
        self.locationShareModel.bagTaskManager?.beginNewBackgroundTask()
        
        if self.locationShareModel.backgroundTimer != nil {
            self.locationShareModel.backgroundTimer?.invalidate()
            self.locationShareModel.backgroundTimer = nil
        }
        self.locationManager!.stopUpdatingLocation()
        self.locationManager?.startUpdatingLocation()
        CommonHelper.writeToFile("Restarting Location Manager ")
    }
    
    func stopLocationManager(){
        self.locationManager!.stopUpdatingLocation()
        CommonHelper.writeToFile("Location Manager Stopped ")
    }
    
    func stopDynamicRegions(){
         isUserIdleRegionToMonitorCreated = false
        for region in self.locationManager!.monitoredRegions {
                CommonHelper.writeToFile("Stopping Monitoring Regions For : \(region.identifier)")
                self.locationManager?.stopMonitoring(for: region)
        }
    }
    
    func createDynamicRegionToMonitor(){
        stopTimers()
        stopDynamicRegions()
        stopLocationManager()
//        setupLocationManager()
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            if let lastUserLocation = self.userLastLocation {
                
                
                let dynamicRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lastUserLocation.coordinate.latitude, longitude: lastUserLocation.coordinate.longitude), radius: 50, identifier: "dynamicRegion \(lastUserLocation.coordinate.latitude) \(lastUserLocation.coordinate.longitude) ")
                
                setupLocationManager()
                self.locationManager!.startMonitoring(for: dynamicRegion)
                
                CommonHelper.writeToFile("Creating dynamic region To Monitor Coordinate : \(lastUserLocation.coordinate.latitude),\(lastUserLocation.coordinate.longitude) ")
  
            }
            
        }
        
        self.locationShareModel.bagTaskManager?.endAllBackgroundTasks()
        CommonHelper.writeToFile("Dynamic Region creations, end all background task ")
        
    }

}

extension LocationManager : CLLocationManagerDelegate, BackgroundMansterTaskExpireDelagte {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        CommonHelper.writeToFile("Location Manager Did Fail With Error : \(error.localizedDescription) ")
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if isUserIdleRegionToMonitorCreated {
            return
        }
        
        self.userLastLocation = locations.last!
        LocationDataAccess.insertLocationToDataBase(userLocation: locations.last!)
        
        if (!isAppInforeground){
            CommonHelper.writeToFile("App Is In The Background")
            
            if(CommonHelper.checkIfUserInIdleState(userLastLocation: locations.last!) && !isUserIdleRegionToMonitorCreated){
                self.locationShareModel.bagTaskManager!.beginNewBackgroundTask()
                CommonHelper.writeToFile("User is idle, creating dynamic region to monitor ")
                createDynamicRegionToMonitor()
                isUserIdleRegionToMonitorCreated = true
                return
            }
            
            if locationShareModel.backgroundTimer != nil{
                return
            }
            
            
            self.locationShareModel.bagTaskManager?.beginNewBackgroundTask()
            
            self.locationShareModel.backgroundTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(restartLocationUpdate), userInfo: nil, repeats: false)
            
            
            if self.locationShareModel.stopLocationManagerAfter10sTimer != nil {
                self.locationShareModel.stopLocationManagerAfter10sTimer?.invalidate()
                self.locationShareModel.stopLocationManagerAfter10sTimer = nil
            }
            
            
            self.locationShareModel.stopLocationManagerAfter10sTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(stopLocationManager), userInfo: nil, repeats: false)

        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        CommonHelper.writeToFile("Location Manager Did Enter Region : \(region.identifier) ")
        stopDynamicRegions()
        restartLocationUpdate()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        CommonHelper.writeToFile("Location Manager Did Exit Region : \(region.identifier) ")
        stopDynamicRegions()
        restartLocationUpdate()
    }
    
    
    func masterTaskExpired() {
        self.locationShareModel.bagTaskManager!.beginNewBackgroundTask()
        
        // Master task expired , restart the background Task
        CommonHelper.writeToFile("Master Task Expired, Called Location Manager Master task expired delegate ")

        createDynamicRegionToMonitor()

    }
    

}
