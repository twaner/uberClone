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
            locationManager.requestAlwaysAuthorization()
        } else {
            // Fallback on earlier versions
        }
        let status = CLLocationManager.authorizationStatus()
        if #available(iOS 8.0, *) {
            if CLLocationManager.locationServicesEnabled() && (status == CLAuthorizationStatus.AuthorizedAlways || status == CLAuthorizationStatus.AuthorizedWhenInUse) && status != .NotDetermined {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
            } else {
                let alertController = UIAlertController(title: "Location Services Disabled", message: "Location Services have been disabled. uberClone will be unbale to determine your location for pickup.", preferredStyle: UIAlertControllerStyle.Alert)
                
                alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ (actions: UIAlertAction) in
                    alertController.dismissViewControllerAnimated(true) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                    })
                alertController.addAction(UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.Default){ (action: UIAlertAction) in
                    if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                    })
                dispatch_async(dispatch_get_main_queue()) {
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            }
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
        print("location \(self.latitude) \(self.longitude)")
        
        // Get Info
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: self.latitude, longitude: self.longitude))
        query.limit = 10
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                guard let objects = objects else {
                    return
                }
                self.locations.removeAll()
                self.usernames.removeAll()
                self.usernames = objects.filter { $0["driverResponded"] as! String == "" || $0.valueForKey("driverResponded") == nil }.map { ($0.valueForKey("username") as? String)!}

//                self.usernames = objects.map { $0.valueForKey("username") as! String }.filter { $0.valueForKey("driverResponded") == "" || $0!.valueForKey("driverResponded") == nil }
                
                self.locations = objects.map { return CLLocationCoordinate2DMake(($0["location"] as? PFGeoPoint)!.latitude, ($0["location"] as? PFGeoPoint)!.longitude) }
                
                self.distances = self.locations.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distanceFromLocation(CLLocation(latitude: self.latitude, longitude: self.longitude)) / 1000 }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            } else {
                //ERROR
            }
        }
        if PFUser.currentUser() != nil {
            self.saveDriverLocation()
        }
    }
    
    func saveDriverLocation() {
        let query = PFQuery(className: "DriverLocation")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                if objects?.first != nil {
                    // Update
                    for object in objects! {
                        let query = PFQuery(className: "DriverLocation")
                        query.getObjectInBackgroundWithId(object.objectId!) { (object: PFObject?, error: NSError?) -> Void in
                            if error == nil {
                                if let object = object {
                                    object["driverLocation"] = PFGeoPoint(latitude: self.latitude, longitude: self.longitude)
                                    object.saveInBackground()
                                }
                            } else if error != nil {
                                print(error?.localizedDescription)
                            }
                        }
                    }
                } else {
                    // if let objects = objects did not satisfy
                    let driverLocation = PFObject(className: "DriverLocation")
                    driverLocation["username"] = PFUser.currentUser()!.username!
                    driverLocation["driverLocation"] = PFGeoPoint(latitude: self.latitude, longitude: self.longitude)
                    driverLocation.saveInBackground()
                }
            } else {
                print("error querying DriverLocation")
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error on location \(error.localizedDescription)")
    }
    
    @IBAction func logoutButtonTapped(sender: AnyObject) {
        
    }
    

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
