//
//  MapViewController.swift
//  immeta
//
//  Created by ribencong on 2021/7/18.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func sendLocation(location : locationMsg)
}
//typealias returnLocation = (locationMsg?) -> Void

class MapViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var locationDesc: UITextView!
    
    @IBOutlet weak var sendBtn: UIButton!
    
    
    let manager = CLLocationManager()
    var locationInfo = locationMsg.init()
    var isMsg: Bool = false
    var sendMsg: MessageItem?
    
//    var returnLoc: returnLocation!
    var delegate: MapViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isMsg {
            showLocationMsg()
            sendBtn.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func showLocationMsg() {
        if let localMsg = sendMsg?.payload as? locationMsg {
            let str = localMsg.str
            self.locationDesc.text = str

            let local = CLLocation.init(latitude: CLLocationDegrees(localMsg.la), longitude: CLLocationDegrees(localMsg.lo))
            
            self.renderPin(local)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !isMsg, let location = locations.first {
            manager.startUpdatingLocation()
            
            let GCJLocation = transWGSToGCJ(location)
            
            self.locationInfo.la = Float(GCJLocation.coordinate.latitude)
            self.locationInfo.lo = Float(GCJLocation.coordinate.longitude)
            
//            DispatchQueue.main.async {
                self.renderPin(GCJLocation)
//            }
            
            let geocoder = CLGeocoder.init()
            geocoder.reverseGeocodeLocation(GCJLocation) { (placemarks, error) in
                if let place = placemarks?.first {
                    if let thoroughfare = place.thoroughfare {
                        self.locationInfo.str = thoroughfare
                        self.locationDesc.text = thoroughfare
                    }
                }

            }
            
        }
    }
    
    func transWGSToGCJ(_ location: CLLocation) -> CLLocation {
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let GCJCoordinate = LocationUtils.transformWGSToGCJ(wgsLocation: coordinate)
        
        let GCJLocation = CLLocation.init(latitude: GCJCoordinate.latitude, longitude: GCJCoordinate.longitude)
        
        return GCJLocation
    }
    
    func renderPin(_ location: CLLocation) {
        
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        // Zoom level
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
        
    }
    
    @IBAction func backBtn(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sendLocation(_ sender: Any) {
        print("------>>>locationInfo=>\(locationInfo)")
//        self.returnLoc(locationInfo)
        
        self.delegate?.sendLocation(location: locationInfo)
        manager.stopUpdatingLocation()
        
//        self.navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }

}
