//
//  Location+CoreDataProperties.swift
//  RegionFinal
//
//  Created by Krishan Sunil Premaretna on 22/5/17.
//  Copyright © 2017 Krishan Sunil Premaretna. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var humanreadable: String?
    
    func isEqualToCoreLocation(_ location : CLLocation) -> Bool{
        
//        CommonHelper.writeToFile("isEqualToCoreLocation : Exisiting Coordinate \(latitude),\(longitude) , New Location To Insert \(location.coordinate.latitude),\(location.coordinate.longitude) , Distance Between Two locations \(location.distance(from: CLLocation(latitude: latitude, longitude: longitude))) ")
        
        var isEqual : Bool = false
        
        if(location.distance(from: CLLocation(latitude: latitude, longitude: longitude)) < 50 ) {
      
            isEqual = true
        }
        
        
        return isEqual
    }
    
    func isIdleUserLocation(_ location : CLLocation) -> Bool {
        
        // If location distance less than 100m and Time is greater than 5 minutes , assume user is in idle state
        if( isEqualToCoreLocation(location) && location.timestamp.timeIntervalSince(self.timestamp! as Date) > 5*60){
            CommonHelper.writeToFile("User In Idle State ")
            return true
        }
        
        return false
    }

}
