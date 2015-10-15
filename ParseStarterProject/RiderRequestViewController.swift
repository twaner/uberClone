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
    
    var requestLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    var requestUsername: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.configureMap()
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
