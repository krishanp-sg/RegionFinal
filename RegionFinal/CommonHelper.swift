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
    
    
    static func checkIfUserInIdleState(userLastLocation : CLLocation) -> Bool{
               
        if let lastInsertedLocation = LocationDataAccess.getLastInsertedUserLocation() {
            
            if (lastInsertedLocation.isIdleUserLocation(userLastLocation)) {
                
                return true
            }
        }

        return false
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
