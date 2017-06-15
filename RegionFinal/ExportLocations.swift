//
//  ExportLocations.swift
//  RegionFinal
//
//  Created by Krishan Sunil Premaretna on 14/6/17.
//  Copyright © 2017 Krishan Sunil Premaretna. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import CoreLocation
import Polyline
import SwiftKeychainWrapper

class ExportLocations: NSObject {
    
    static let sharedInstance = ExportLocations()
    internal fileprivate(set) var isUploadingDataToServer:Bool
    
    typealias SuccessHandler = (_ userLocationsTransfered:[Location]) -> Void
    typealias FailureHandler = (_ errorMessage:String?) -> Void
    
    //API To Upload Data To Server
    fileprivate let IMPORT_DATA_API = "http://121.6.225.31:28080/api/location/ImportLocation"
    
    override fileprivate init(){
        // TODO :- Any Custom Initalization
        self.isUploadingDataToServer = false
    }
    
    
    
    
    
    // MARK :  - Call Webservice to update data
    func uploadDataToServer(_ userLocationsToSend:[Location],succesHandler:@escaping SuccessHandler, failureHandler:@escaping FailureHandler) {
        
        if isUploadingDataToServer {
            // Uploading Data To Server , Please wait while it finishes
            return
        }
        
        if userLocationsToSend.count <= 0 {
            return
        }
        
      let sortedUserLocations =  userLocationsToSend.sorted(by: { $0.timestamp!.timeIntervalSinceReferenceDate < $1.timestamp!.timeIntervalSinceReferenceDate  })
        
        isUploadingDataToServer = true
        
        var uniqueDevieID = ""
        
        let retrievedString: String? =  KeychainWrapper.standard.string(forKey: "uniqueID")
        if let uniqueID =  retrievedString {
            uniqueDevieID = uniqueID
        } else {
            uniqueDevieID = UUID().uuidString
            KeychainWrapper.standard.set(uniqueDevieID, forKey: "uniqueID")
        }
        
        
        var polyLineString:String! = String()
        var second_accuray_modeString:String! =  String()
        var cordinatesArray : [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
        
        // Find the base Date
        let dateFormater : DateFormatter = DateFormatter()
        let timeZone = TimeZone.autoupdatingCurrent
        dateFormater.timeZone = timeZone
        dateFormater.dateFormat = "yyMMdd" // eg : 160727 - July 27 2016
        let baseDate = dateFormater.string(from: sortedUserLocations.first!.timestamp! as Date)
        
         let midnightDate =   CommonHelper.getGMTModifiedDate(date: sortedUserLocations.first!.timestamp! as Date)
        
        let baseDateToCheck = midnightDate
        var previous_second_accuracy_modeString = ""
        
        for locaion in sortedUserLocations {
            
            let second : Int = Int(locaion.timestamp!.timeIntervalSince(baseDateToCheck as Date))
            
            
            let hexadecimalStringOfSeconds = String(second, radix: 16)//NSString(format:"%2x", second) as String
            
            let stringToSend = "\(hexadecimalStringOfSeconds)|65|3"
            
            if previous_second_accuracy_modeString == stringToSend {
                continue
            }
            
            previous_second_accuracy_modeString = stringToSend
            
            let cordinate = CLLocationCoordinate2D(latitude: locaion.latitude , longitude: locaion.longitude)
            cordinatesArray.append(cordinate)
            
            if second_accuray_modeString == "" {
                second_accuray_modeString = stringToSend
                continue
            }
            second_accuray_modeString.append("_\(stringToSend)")
            
        }
        
        
        polyLineString = Polyline(coordinates: cordinatesArray).encodedPolyline
        
        let params:[String:AnyObject] = ["u":uniqueDevieID as AnyObject,
                                         "d":baseDate as AnyObject,
                                         "p":polyLineString as AnyObject,
                                         "f":second_accuray_modeString as AnyObject]
        
        debugPrint("Parameters To Send : \(params)")
        
//        let header = [
//            "Content-Type": "application/json"
//        ]
        
        
        
        // This is to run the Alamofire request in the background
        // Normal Alamofire requests are asynchronus but theire call backs are made in main thread
        // This will make the response call back to be perform in background queue
        _ = DispatchQueue(label: "com.manjalabs.hugo-iOS-locationCollection", attributes: DispatchQueue.Attributes.concurrent)
        
        Alamofire.request(IMPORT_DATA_API, method: .post, parameters: params, encoding: URLEncoding.default, headers: nil).responseJSON{ response in
            
            UserDefaults.standard.setValue(NSDate(), forKey: "last_synced")
            
            debugPrint(response)
            if let result = response.result.value as? [String:AnyObject] {
                let successIndicator = result["Success"] as! Bool
                self.isUploadingDataToServer = false
                if successIndicator {
                    debugPrint("Post Success")
                    succesHandler(sortedUserLocations)
                    
                }else {
                    debugPrint("Post Failure")
                    failureHandler(result["Message"] as? String)
                }
                
                
            } else {
                debugPrint("Post Failure")
                self.isUploadingDataToServer = false
                failureHandler(response.result.error?.localizedDescription)
                
            }
            
        }
        
    }


}
