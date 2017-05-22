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
    
    static let sharedManager = LocationManager()
    var locationManager : CLLocationManager?
    var isAppInforeground : Bool = false
    var locationShareModel = LocationShareModel.sharedInstance
    
    func setupLocationManager(){
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager?.requestAlwaysAuthorization()
        self.locationManager?.startUpdatingLocation()
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            let samsungHubRegion = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 1.283577, longitude: 103.849670), radius: 100, identifier: "SamsungHub")
            
            let hougang = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 1.372576, longitude: 103.888259), radius: 100, identifier: "hougnag")
            
            self.locationManager!.startMonitoring(for: samsungHubRegion)
            self.locationManager!.startMonitoring(for: hougang)
        }
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
        
        if self.locationShareModel.backgroundTimer != nil {
            self.locationShareModel.backgroundTimer?.invalidate()
            self.locationShareModel.backgroundTimer = nil
        }
        
        if self.locationShareModel.stopLocationManagerAfter10sTimer != nil {
            self.locationShareModel.stopLocationManagerAfter10sTimer?.invalidate()
            self.locationShareModel.stopLocationManagerAfter10sTimer = nil
        }
        
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
        self.locationManager?.stopUpdatingLocation()
        CommonHelper.writeToFile("Location Manager Stopped ")
    }

}

extension LocationManager : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        CommonHelper.writeToFile("Location Manager Did Fail With Error : \(error.localizedDescription) ")
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CommonHelper.writeToFile("Location Manager Did Update Location: \(locations.last!.coordinate.latitude),\(locations.last!.coordinate.longitude) ")
        LocationDataAccess.insertLocationToDataBase(userLocation: locations.last!)
        
        
        if (!isAppInforeground){
            CommonHelper.writeToFile("App Is In The Background")
            
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
        restartLocationUpdate()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        CommonHelper.writeToFile("Location Manager Did Exit Region : \(region.identifier) ")
        restartLocationUpdate()
    }
    
    
    

}
