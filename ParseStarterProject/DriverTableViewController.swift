//
//  DriverTableViewController.swift
//  uberClone
//
//  Created by Taiowa Waner on 10/14/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit
import Foundation

class DriverTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    var usernames = [String]()
    var locations = [CLLocationCoordinate2D]()
    var distances = [CLLocationDistance]()
    let locationManager = CLLocationManager()
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if #available(iOS 9.0, *) {
            locationManager.requestLocation()
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 8.0, *) {
            locationManager.requestWhenInUseAuthorization()
        } else {
            // Fallback on earlier versions
        }

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
         self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.usernames.count ?? 0
    }
    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        let distance = String.localizedStringWithFormat("%.2f %@", Double(distances[indexPath.row]),"km")
        cell.textLabel?.text = self.usernames[indexPath.row] + " - " + distance
        
        return cell
    }
    
    // MARK: - CLLocation
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocationCoordinate2D = (manager.location?.coordinate)!
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        // Get Info
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: self.latitude, longitude: self.longitude))
        query.limit = 10
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                print("retieved \(objects?.count)")
                guard let objects = objects else {
                    return
                }
                self.locations.removeAll()
                self.usernames.removeAll()
                self.usernames = objects.map { return ($0["username"] as? String)! }
                self.locations = objects.map { return CLLocationCoordinate2DMake(($0["location"] as? PFGeoPoint)!.latitude, ($0["location"] as? PFGeoPoint)!.longitude) }
                
                self.distances = self.locations.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distanceFromLocation(CLLocation(latitude: self.latitude, longitude: self.longitude)) / 1000 }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            } else {
                //ERROR
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error on location \(error.localizedDescription)")
    }
    
    @IBAction func logoutButtonTapped(sender: AnyObject) {
//        self.performSegueWithIdentifier("DriverLogoutSegue", sender: self)
    }
    

    /*
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DriverLogoutSegue" {
            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: false)
            PFUser.logOut()
        } else if segue.identifier == "ShowRiderLocationSegue" {
            let destinationVC = segue.destinationViewController as? RiderRequestViewController
            destinationVC?.requestLocation = locations[(tableView.indexPathForSelectedRow?.row)!]
            destinationVC?.requestUsername = usernames[(tableView.indexPathForSelectedRow?.row)!]
        }
    }


}
