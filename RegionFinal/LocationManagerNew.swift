//
//  LocationManagerNew.swift
//  RegionFinal
//
//  Created by Krishan Sunil Premaretna on 13/6/17.
//  Copyright © 2017 Krishan Sunil Premaretna. All rights reserved.
//

import UIKit
import CoreLocation

class LocationManagerNew: NSObject {
    
    let distanceFilter = 50.0
    let samsungHubIdentifier = "SamsungHub"
    let hounganIdentifier = "hougnag"
    
    static let sharedManager = LocationManagerNew()
    var locationManager : CLLocationManager?
    var significantLocationManager : CLLocationManager?
    var isAppInforeground : Bool = false
    var locationShareModel = LocationShareModel.sharedInstance
    var isAppLaunchedFromLocationKey = false
    var isLocationUpdating = false
    var isUserIdleRegionToMonitorCreated = false
    
    var userLastLocation : CLLocation?
    
    func setupLocationManager(){
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager!.allowsBackgroundLocationUpdates = true
        self.locationManager?.requestAlwaysAuthorization()
        self.locationManager?.startUpdatingLocation()
        
        if isAppLaunchedFromLocationKey {
            setupSignificantLocationManagerUpdate()
        }
        
//        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
//        
//            let samsungHubRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 1.283577, longitude: 103.849670), radius: 10, identifier: samsungHubIdentifier)
//        
//            let hougang = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 1.372576, longitude: 103.888259), radius: 10, identifier: hounganIdentifier)
//        
//            self.locationManager!.startMonitoring(for: samsungHubRegion)
//            self.locationManager!.startMonitoring(for: hougang)
//        }
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
        
        notificationCenter.addObserver(self, selector: #selector(appWillTerminate), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
        
        self.locationShareModel.bagTaskManager = BackgroundTaskManager.shared()
        self.locationShareModel.bagTaskManager!.delegate = self
    }
    
    func appMovedToBackground(){
        isAppInforeground = false
        CommonHelper.writeToFile("App Moved To Background ")
        
        self.locationShareModel.bagTaskManager?.beginNewBackgroundTask()
        self.locationManager!.stopUpdatingLocation()
        self.locationManager?.startUpdatingLocation()
        
        // setup Significant Location Update
        setupSignificantLocationManagerUpdate()
    }
    
    func appMovedToForeground(){
        isAppInforeground = true
        isAppLaunchedFromLocationKey = false
        CommonHelper.writeToFile("App Moved To Foreground ")
        
        if self.locationShareModel.backgroundTimer != nil {
            self.locationShareModel.backgroundTimer?.invalidate()
            self.locationShareModel.backgroundTimer = nil
        }
        
        if self.locationShareModel.stopLocationManagerAfter10sTimer != nil {
            self.locationShareModel.stopLocationManagerAfter10sTimer?.invalidate()
            self.locationShareModel.stopLocationManagerAfter10sTimer = nil
        }
        
        self.locationManager!.startUpdatingLocation()
        
        stopSignificantLocationUpdate()
    }
    
    func appDidBecomeActive(){
        isAppInforeground = true
        CommonHelper.writeToFile("App Did Become Active ")
    }
    
    func appWillTerminate(){
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
        self.locationManager?.stopUpdatingLocation()
        CommonHelper.writeToFile("Location Manager Stopped ")
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
    
    func stopDynamicRegions(){
        isUserIdleRegionToMonitorCreated = false
        for region in self.locationManager!.monitoredRegions {
            
            if region.identifier == samsungHubIdentifier || region.identifier == hounganIdentifier {
                continue
            }
            
            CommonHelper.writeToFile("Stopping Monitoring Regions For : \(region.identifier)")
            self.locationManager?.stopMonitoring(for: region)
        }
    }

    
    func createDynamicRegionToMonitor(){
        stopTimers()
        stopDynamicRegions()
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            if let lastUserLocation = self.userLastLocation {
                
                
                let dynamicRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: lastUserLocation.coordinate.latitude, longitude: lastUserLocation.coordinate.longitude), radius: 10, identifier: "dynamicRegion \(lastUserLocation.coordinate.latitude) \(lastUserLocation.coordinate.longitude) ")
                
                self.locationManager!.startMonitoring(for: dynamicRegion)
                stopLocationManager()
                CommonHelper.writeToFile("Creating dynamic region To Monitor Coordinate : \(lastUserLocation.coordinate.latitude),\(lastUserLocation.coordinate.longitude) ")
            }
        }
    }
    
    
    // Setup Significant Location Update
    func setupSignificantLocationManagerUpdate(){
        self.significantLocationManager = CLLocationManager()
        self.significantLocationManager!.delegate = self
        self.significantLocationManager!.requestAlwaysAuthorization()
        self.significantLocationManager!.startMonitoringSignificantLocationChanges()
    }
    
    func stopSignificantLocationUpdate(){
        if let significantLocationManger = self.significantLocationManager {
            significantLocationManger.stopMonitoringSignificantLocationChanges()
            self.significantLocationManager = nil
        }
    }


}

extension LocationManagerNew : CLLocationManagerDelegate, BackgroundMansterTaskExpireDelagte {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        CommonHelper.writeToFile("Location Manager Did Fail With Error : \(error.localizedDescription) ")
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if isLocationUpdating || isUserIdleRegionToMonitorCreated {
            return
        }
        self.userLastLocation = locations.last
        isLocationUpdating = true
        CommonHelper.writeToFile("Location Manager Did Update Location: \(locations.last!.coordinate.latitude),\(locations.last!.coordinate.longitude)  \(manager == self.locationManager ? "Location Manager":"Significant") ")
        LocationDataAccess.insertLocationToDataBase(userLocation: locations.last!)
        isLocationUpdating = false
        
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
        CommonHelper.writeToFile("Master task expired ")
        self.locationShareModel.bagTaskManager!.beginNewBackgroundTask()
        CommonHelper.writeToFile("User is idle, creating dynamic region to monitor ")
        createDynamicRegionToMonitor()
        isUserIdleRegionToMonitorCreated = true
    }
}
