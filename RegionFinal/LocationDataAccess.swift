//
//  LocationDataAccess.swift
//  Location_Collection
//
//  Created by Krishan Sunil Premaretna on 27/4/17.
//  Copyright © 2017 Krishan Sunil Premaretna. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class LocationDataAccess: NSObject {
    
     fileprivate static let retriveDeleteManagerObjectContext : NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    
     typealias UserLocationRetrivedhandler = (_ userLocations:[Location]?) -> Void
    
    static let applicaitonDelegate = UIApplication.shared.delegate as? AppDelegate
    
    static func getMainContext() -> NSManagedObjectContext {
        
        return CoreDataController.sharedInstance.managedObjectContext
        
    }
    
    public static func getContext() -> NSManagedObjectContext {
        
        
        if retriveDeleteManagerObjectContext.persistentStoreCoordinator == nil {
            retriveDeleteManagerObjectContext.persistentStoreCoordinator = getMainContext().persistentStoreCoordinator
        }
        
        return retriveDeleteManagerObjectContext
    }

    
    static func insertLocationToDataBase( userLocation : CLLocation) -> Bool {
        
        guard applicaitonDelegate != nil else {
            return false
        }
        
        if let lastInsertedLocation = getLastInsertedUserLocation() {
            
            if (lastInsertedLocation.isEqualToCoreLocation(userLocation)) {
                
                return false
            }
            
        }
        
        // This is to run the Coredata SAve in Background
//        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        privateContext.persistentStoreCoordinator = getMainContext().persistentStoreCoordinator
//        privateContext.perform {
        
            let entity = NSEntityDescription.entity(forEntityName: "Location", in: getMainContext())
            let location = NSManagedObject(entity: entity!, insertInto: getMainContext())
            
            location.setValue( userLocation.coordinate.latitude , forKey: "latitude")
            location.setValue( userLocation.coordinate.longitude , forKey: "longitude")
            //        location.setValue( Int(userLocation.horizontalAccuracy), forKey: "accuracy")
            location.setValue(Date(), forKey: "timestamp")
            location.setValue(CommonHelper.convertDateToString(dateToConvert: Date()), forKey: "humanreadable")
            
            do {
                try getMainContext().save()
                CommonHelper.writeToFile("Location Inserted coordinates : \(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude) ")
                return true
            } catch let error as NSError {
                print("Could Not Save. \(error) , \(error.localizedDescription)")
                return false
            }
            
//        }

    }
    
    
    static func getLastInsertedUserLocation() -> Location? {

        guard applicaitonDelegate != nil else {
            return nil
        }
        
        
        
        let fetchRequest : NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.sortDescriptors = [ NSSortDescriptor.init(key: "timestamp", ascending: false) ]
        fetchRequest.fetchLimit = 1
        
        
        do {
            let result = try getContext().fetch(fetchRequest)
            return result.last
        } catch let error as NSError {
            print("Could Not Fetch any Object . \(error) \(error.localizedDescription)")
            
        }
        
        return nil
    }
    
    static func getRecentLocations(recentLocationCount : Int) -> [Location] {
        guard applicaitonDelegate != nil else {
            return [Location]()
        }

        let fetchRequest : NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.sortDescriptors = [ NSSortDescriptor.init(key: "timestamp", ascending: false) ]
        fetchRequest.fetchLimit = recentLocationCount
        
        
        do {
            let result = try getContext().fetch(fetchRequest)
            return result
        } catch let error as NSError {
            print("Could Not Fetch any Object . \(error) \(error.localizedDescription)")
            
        }
        
        return [Location]()

    }
    
    static func getRecentLocations(timeInMinutes : Int) -> [Location] {
        
        guard applicaitonDelegate != nil else {
            return [Location]()
        }
        
        let fetchRequest : NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.sortDescriptors = [ NSSortDescriptor.init(key: "timestamp", ascending: false) ]
        
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .minute, value: -timeInMinutes, to: Date())
        let predicate = NSPredicate(format: "timestamp > %@", date! as NSDate)
        fetchRequest.predicate = predicate
        
        
        do {
            let result = try getContext().fetch(fetchRequest)
            return result
        } catch let error as NSError {
            print("Could Not Fetch any Object . \(error) \(error.localizedDescription)")
            
        }
        
        return [Location]()
    }
    
    static func retriveUserLocation(_ retrivedHandler:@escaping UserLocationRetrivedhandler)  {
        var locations : [Location] = [Location]()
        
        getContext().perform {
            
            let fetchRequest : NSFetchRequest<Location> = Location.fetchRequest()
            fetchRequest.sortDescriptors = [ NSSortDescriptor.init(key: "timestamp", ascending: false) ]            
            
            do {
                locations = try retriveDeleteManagerObjectContext.fetch(fetchRequest)
                
            } catch let error as NSError {
                debugPrint("Coulnd Not Retrive data \(error), Description : \(error.localizedDescription)")
            }
            
            retrivedHandler(locations)
            
            
        }
    }
    
    
    static func deleteTransferedUserLocations(_ userLocations:[Location]) {
        
     getContext().perform {
            
            for userLocaion in userLocations {
                retriveDeleteManagerObjectContext.delete(userLocaion)
            }
            
            do {
                try retriveDeleteManagerObjectContext.save()
                debugPrint("Objects Deleted")
            } catch let error as NSError {
                debugPrint("Deleting objects Error : \(error.localizedDescription)")
            }
            
        }
        
    }
    

}
