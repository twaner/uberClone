//
//  UserViewController.swift
//  uberClone
//
//  Created by Taiowa Waner on 10/13/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import Parse
import UIKit
import MapKit

class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var spiner: UIActivityIndicatorView!
    
    let locationManager = CLLocationManager()
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var riderRequestActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
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
        
        let status = CLLocationManager.authorizationStatus()
        if #available(iOS 8.0, *) {
            if CLLocationManager.locationServicesEnabled() && (status == CLAuthorizationStatus.AuthorizedAlways || status == CLAuthorizationStatus.AuthorizedWhenInUse) && status != .NotDetermined {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.requestAlwaysAuthorization()
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

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBOutlet weak var callButtonTapped: UIButton!

    @IBAction func callButtonTapped(sender: AnyObject) {
        if !riderRequestActive {
            self.spiner.startAnimating()
            let riderRequest = PFObject(className: "RiderRequest")
            riderRequest["username"] = PFUser.currentUser()?.username
            riderRequest["location"] = PFGeoPoint(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
            print("latitude: \(locationManager.location?.coordinate.latitude)!, longitude: \(locationManager.location?.coordinate.longitude)")
            
            riderRequest.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
                if (success) {
                    self.callButtonTapped.setTitle("Cancel Uber", forState: .Normal)
                    self.spiner.stopAnimating()
                } else {
                    // ERROR saving
                    print("error calling uber \(error!.localizedDescription)")
                    self.spiner.stopAnimating()
                    if #available(iOS 8.0, *) {
                        let alert = UIAlertController(title: "Error", message: "cannot call uber \(error!.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    } else {
                        // Fallback on earlier versions
                    }
                }
                self.riderRequestActive = true
            }
        } else {
            // riderRequestACtive == true
            self.spiner.startAnimating()
            self.riderRequestActive = false
            self.callButtonTapped.setTitle("Call Uber", forState: .Normal)
            let query = PFQuery(className: "RiderRequest")
            query.whereKey("username", equalTo: (PFUser.currentUser()?.username!)!)
            query.findObjectsInBackgroundWithBlock(){ (objects: [PFObject]?, error: NSError?) -> Void in
                if error == nil {
                    if let objects = objects {
                        for object in objects {
                            object.deleteInBackground()
                        }
                    }
                    self.spiner.stopAnimating()
                } else {
                    print(error!)
                    self.spiner.stopAnimating()
                }
            }
        }
    }
    
    // MARK: - CLLocation
    
    func configureMap(location: CLLocationCoordinate2D) -> MKPointAnnotation {
        let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpanMake(0.01, 0.01))
        self.mapView.setRegion(region, animated: true)
        
        let pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = pinLocation
        return objectAnnotation
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        let location: CLLocationCoordinate2D = (manager.location?.coordinate)!
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) -> Void in
            if error != nil {
                print("error finding RiderRequest \(error?.localizedDescription)")
            } else {
//                objects?.forEach(dispatch_async(dispatch_get_main_queue()) {
//                    self.callButtonTapped.setTitle("Driver is ", forState: .Normal)
//                    })
                for object in objects! {
                    if let driverUsername = object["driverResponded"] {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.callButtonTapped.setTitle("Driver \(driverUsername), is on the way", forState: .Normal)
                        }
                        let query = PFQuery(className: "DriverLocation")
                        query.whereKey("username", equalTo: driverUsername)
                        query.findObjectsInBackgroundWithBlock() { (objects: [PFObject]?, error: NSError?) -> Void in
                            if error == nil {
                                for object in objects! {
                                    if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                        print("driverLocation \(driverLocation)")
                                        let distance = (CLLocation(latitude: self.latitude, longitude: self.longitude)).distanceFromLocation(CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude))
                                        let distanceString = String.localizedStringWithFormat(".2f %@", Double(distance), "km away")
                                        dispatch_async(dispatch_get_main_queue()) {
                                            self.callButtonTapped.setTitle("Driver \(driverUsername), is \(distanceString)", forState: .Normal)
                                        }
                                    }
                                }
                            } else {
                                print("Error finding DriverLocation w/ username \(error!.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
        self.mapView.addAnnotation(self.configureMap(location))
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error on location \(error.localizedDescription)")
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "LogoutRiderSegue") {
            PFUser.logOutInBackground()
        } 
    }
}
