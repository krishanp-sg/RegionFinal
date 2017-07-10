//
//  CommonHelper.swift
//  Location_Collection
//
//  Created by Krishan Sunil Premaretna on 27/4/17.
//  Copyright © 2017 Krishan Sunil Premaretna. All rights reserved.
//

import UIKit
import CoreLocation

class CommonHelper: NSObject {
    static let file : String = "log.txt"
    
    static func convertDateToString(dateToConvert : Date) -> String {
       
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        let yourDate = formatter.date(from: myString)
        formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"
        let myStringafd = formatter.string(from: yourDate!)
        
        return myStringafd
    }
    
    static func writeToFile(_ stringToWrite : String){
        
        debugPrint(stringToWrite)
        do {
            let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL
            let url = dir.appendingPathComponent(file)
            let text = "\n"+stringToWrite + "\(convertDateToString(dateToConvert: Date()))"
            try text.appendLineToURL(fileURL: url as URL)
        }
        catch {
            print("Could not write to file")
        }    

    }
    
    static func checkIfuserInIdleState(backgroundUserLocations : [LocationManagerNew.TemperaryLocation])-> Bool {
        
        if backgroundUserLocations.count == 0 {
            return true
        }
        
//        if Date().timeIntervalSince(backgroundUserLocations.first!.date) < 3*60 {
//            return false
//        }
        
        var idlePoints = 0
        
        for i in 0..<backgroundUserLocations.count {
            var ava_lat = 0.0
            var ava_long = 0.0
            var size = 0.0
            
            for j in 0...i {
                let tempLocation = backgroundUserLocations[j].location
                ava_lat += tempLocation!.coordinate.latitude
                ava_long += tempLocation!.coordinate.longitude
                size += 1
            }
            
            let averageLocation = CLLocation(latitude: ava_lat/size, longitude: ava_long/size)
            let distance = backgroundUserLocations.last!.location.distance(from: averageLocation)
            
            if distance < 200 {
                idlePoints += 1
            }
        }
        
        
        let idelPercentage = (Double(idlePoints) / Double(backgroundUserLocations.count)) * 100
        
        if idelPercentage < 75 {
            return false
        }
        
        
        return true
    }
    
    static func checkIfUserInIdleState(userLastLocation : CLLocation) -> Bool{
        
        let last5minUserlocations = LocationDataAccess.getRecentLocations(timeInMinutes: 5)
        
        if last5minUserlocations.count == 0 {
            return true
        }
        
        var idlePoints = 0
        let lastLocation = CLLocation(latitude: userLastLocation.coordinate.latitude, longitude: userLastLocation.coordinate.longitude)
        for  i in 0..<last5minUserlocations.count {
            var ava_lat = 0.0
            var ava_long = 0.0
            var size = 0.0
           
            for j in 0...i{
                let tempLocation = last5minUserlocations[j]
                ava_lat += tempLocation.latitude
                ava_long += tempLocation.longitude
                size += 1
            }
            
            let averageLocaton = CLLocation(latitude: (ava_lat/size), longitude: (ava_long/size))
            
            let distance = lastLocation.distance(from: averageLocaton)
            
            if distance < 100 && distance != 0 {
                idlePoints += 1
            }
        }
        
        
        let idlePercentage = (idlePoints/last5minUserlocations.count)*100
        
        if idlePercentage < 75 {
            return false
        }
        
        return true
               
//        if let lastInsertedLocation = LocationDataAccess.getLastInsertedUserLocation() {
//            
//            if (lastInsertedLocation.isIdleUserLocation(userLastLocation)) {
//                
//                return true
//            }
//        }
//
//        return false
    }
    
    static func getCurrentDate() -> Date {
        
        let date = Date()
        let newDate = getCurrentDate(date: date)
        
        return newDate
    }
    
    static func getCurrentDate(date:Date) -> Date {
        
        let timeZone = TimeZone.current
        let seconds =  timeZone.secondsFromGMT(for: date)
        let newDate = Date(timeInterval: TimeInterval(seconds), since: date)
        
        return newDate
    }
    
    static func getGMTModifiedDate(date:Date) -> Date{
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd"
        dateFormater.timeZone = TimeZone(secondsFromGMT: 0)
        let dateString = dateFormater.string(from: date)
        
        let newDate =  NSCalendar.current.startOfDay(for: dateFormater.date(from: dateString)!)
        return getCurrentDate(date: newDate)
    }


}

extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }
    
    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}

extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
