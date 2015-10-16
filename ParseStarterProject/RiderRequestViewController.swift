//
//  RiderRequestViewController.swift
//  uberClone
//
//  Created by Taiowa Waner on 10/14/15.
//  Copyright © 2015 Parse. All rights reserved.
//

import UIKit
import MapKit
import Parse

class RiderRequestViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pickupRider: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    let locationManager = CLLocationManager()
    var requestLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var requestUsername: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.locationManager.delegate = self
        self.configureMap()
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
    
    @IBAction func pickupRider(sender: UIButton) {
        let query = PFQuery(className: "RiderRequest")
        query.whereKey("username", equalTo: requestUsername)
        query.findObjectsInBackgroundWithBlock(){ (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects {
                    for object in objects {
                        let query = PFQuery(className: "RiderRequest")
                        query.getObjectInBackgroundWithId(object.objectId!, block: { (object: PFObject?, error: NSError?) -> Void in
                            if object != nil {
                                object!["driverResponded"] = PFUser.currentUser()?.username
                                do {
                                    try object!.save()
                                } catch let error {
                                    print("SAVE ERROR \(error)")
                                }
                                CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: self.requestLocation.latitude, longitude: self.requestLocation.longitude)) { (placemarks: [CLPlacemark]?, error: NSError?) -> Void in
                                    if (error != nil) {
                                        print(error?.localizedDescription)
                                    } else {
                                        if placemarks?.count > 0 {
                                            // Allow Apple Maps to provider directions
                                            let mapItem = MKMapItem(placemark: MKPlacemark(placemark: (placemarks?.first)!))
                                            mapItem.name = self.requestUsername
                                            let launchOptions = [MKLaunchOptionsDirectionsModeKey   : MKLaunchOptionsDirectionsModeDriving]
                                            mapItem.openInMapsWithLaunchOptions(launchOptions)
                                        } else {
                                            print("No Placemarks")
                                        }
                                    }
                                }
                            } else {
                                print("FIND BY ID \(error)")
                            }
                        })
                    }
                }
            } else {
                print("FIND ERROR \(error!)")
            }
        }
    }
    
    func mapViewWillStartLoadingMap(mapView: MKMapView) {
        dispatch_async(dispatch_get_main_queue()) {
            self.spinner.startAnimating()
        }
    }
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        if fullyRendered {
            dispatch_async(dispatch_get_main_queue()) {
                self.spinner.stopAnimating()
            }
        }
    }
    
    
    func configureMap() {
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpanMake(0.01, 0.01))
        self.mapView.setRegion(region, animated: true)
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = requestLocation
        objectAnnotation.title = requestUsername
        objectAnnotation.subtitle = "Is requesting a ride."
        self.mapView.addAnnotation(objectAnnotation)
    }
    
    // MARK: - CLLocationManager
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
