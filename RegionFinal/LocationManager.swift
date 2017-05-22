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

    }
    
    func appMovedToBackground(){
        isAppInforeground = false
    }
    
    func appMovedToForeground(){
        isAppInforeground = true
    }

}

extension LocationManager : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        CommonHelper.writeToFile("Location Manager Did Fail With Error : \(error.localizedDescription) ")
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CommonHelper.writeToFile("Location Manager Did Update Location: \(locations.last!.coordinate.latitude),\(locations.last!.coordinate.longitude) ")
        LocationDataAccess.insertLocationToDataBase(userLocation: locations.last!)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        CommonHelper.writeToFile("Location Manager Did Enter Region : \(region.identifier) ")
//        self.locationManager?.stopUpdatingLocation()
//        setupLocationManager()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        CommonHelper.writeToFile("Location Manager Did Exit Region : \(region.identifier) ")
//        self.locationManager?.stopUpdatingLocation()
//        setupLocationManager()
    }
    
    
    

}
