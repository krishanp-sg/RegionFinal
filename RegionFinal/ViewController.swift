//
//  ViewController.swift
//  RegionFinal
//
//  Created by Krishan Sunil Premaretna on 22/5/17.
//  Copyright © 2017 Krishan Sunil Premaretna. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var locationsCountLabel: UILabel!
    @IBOutlet weak var locationsTableView: UITableView!
    
    fileprivate var locaitons = [Location]()
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        
        let fetchRequest : NSFetchRequest<Location> = Location.fetchRequest()
        fetchRequest.sortDescriptors = [ NSSortDescriptor.init(key: "timestamp", ascending: false) ]
        
//        
//        let fetchedResultsController = NSFetchedResultsController.init(fetchRequest: fetchRequest, managedObjectContext: manageOBC!, sectionNameKeyPath: nil, cacheName: nil)
        
        let frc = NSFetchedResultsController (fetchRequest: fetchRequest, managedObjectContext: LocationDataAccess.getMainContext(), sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self

        
        
        return frc as! NSFetchedResultsController<NSFetchRequestResult>
    }()
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationsTableView.register(UINib(nibName: "LocationCellTableViewCell", bundle: nil), forCellReuseIdentifier: LocationCellTableViewCell.identifier)
        self.locationsTableView.rowHeight = UITableViewAutomaticDimension
        self.locationsTableView.estimatedRowHeight = 117
        
        
        do {
            try self.fetchedResultsController.performFetch()
            
        } catch let error as NSError {
            print("Unable to perform fetch request \(error), \(error.localizedDescription)")
        }

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupRightNavigationBarLabel(_ locationCount : Int){
        self.locationsCountLabel.text = "Location Count : \(locationCount)"
        locationsCountLabel.sizeToFit()
    }


    @IBAction func sendLocationsToServer(_ sender: Any) {
        UploadLocations.sharedLocation.sendLocationBackToServer()
    }
}

extension ViewController : UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let locations = fetchedResultsController.fetchedObjects else {
            return 0
        }
        setupRightNavigationBarLabel(locations.count)
        return locations.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard  let cell = tableView.dequeueReusableCell(withIdentifier: LocationCellTableViewCell.identifier, for: indexPath) as? LocationCellTableViewCell else {
            fatalError("Unexpected Index Path")
        }
        
        let location = self.fetchedResultsController.object(at: indexPath)
        //Configure Cell
        cell.configureCell(location: location as! Location)
        
        return cell
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.locationsTableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.locationsTableView.endUpdates()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                self.locationsTableView.insertRows(at: [indexPath], with: .fade)
            }
            break;
        case .delete:
            if let indexPath = indexPath {
                self.locationsTableView.deleteRows(at: [indexPath], with: .fade)
            }
        default:
            print("...")
        }
    }
    
    
}


