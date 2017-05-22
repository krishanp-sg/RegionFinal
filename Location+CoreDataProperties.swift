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
        
        var isEqual : Bool = false
        
        if(location.distance(from: CLLocation(latitude: latitude, longitude: longitude)) < 100 ) {
            isEqual = true
        }
        
        
        return isEqual
    }

}
