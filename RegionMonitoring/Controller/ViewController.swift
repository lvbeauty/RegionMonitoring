//
//  ViewController.swift
//  RegionMonitoring
//
//  Created by Tong Yi on 7/14/20.
//  Copyright © 2020 Tong Yi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    var geofences = [GeofenceAnnotation]()
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestUserAuthorization()
        checkAuthorition()
        setup()
        stopMonitoringAllRegions()
        addMonitoringAnnotations()
    }
    
    func setup()
    {
        locationManager.delegate = self
        UNUserNotificationCenter.current().delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        geofences.removeAll()
//        UserDefaults.standard.removeObject(forKey: PreferencesKeys.savedItems)
//        let allGeofences = GeofenceAnnotation.allGeofence()
//        for item in allGeofences {
//            addAnnotation(item)
//        }
    }
    
    func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    func checkAuthorition()
    {
        let status = CLLocationManager.authorizationStatus() // need to check for ios 14.0
        switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                print("Approved")
                locationManager.startUpdatingLocation()
            case .notDetermined:
                self.locationManager.requestAlwaysAuthorization()
            default:
                break
        }
    }
    
    func addMonitoringAnnotations() {
        let appleCoordinate = CLLocationCoordinate2D(latitude: 37.3349285, longitude: -122.011033)
        let radius = 1000.00
        let aIdentifier = NSUUID().uuidString
        let aNote = "Left Apple Company!"
        let aEventType: EventType = .beExit
        addGeotificationViewController(didAddCoordinate: appleCoordinate, radius: radius, identifier: aIdentifier, note: aNote, eventType: aEventType)
        
        let googleCoordinate = CLLocationCoordinate2D(latitude: 37.422, longitude: -122.084058)
        let gIdentifier = NSUUID().uuidString
        let gNote = "Enter Google Company!"
        let gEventType: EventType = .beEntry
        addGeotificationViewController(didAddCoordinate: googleCoordinate, radius: radius, identifier: gIdentifier, note: gNote, eventType: gEventType)
    }
    
    //MARK: - Notification
    func requestUserAuthorization()
    {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (status, error) in
            if status
            {
                print("Granted")
            }
            else
            {
                print("Not Granted")
            }
        }
    }
    
    //MARK: - save geofence annotation to the userdefaults
    func saveAllGeofenceAnnotations() {
      let encoder = JSONEncoder()
      do {
        let data = try encoder.encode(geofences)
        UserDefaults.standard.set(data, forKey: PreferencesKeys.savedItems)
      } catch {
        print("error encoding geotifications")
      }
    }
    
    //MARK: - map add & remove annotation Methods
    func addAnnotation(_ geofenceAnnotation: GeofenceAnnotation) {
        geofences.append(geofenceAnnotation)
        mapView.addAnnotation(geofenceAnnotation)
        addRadiusOverlay(for: geofenceAnnotation)
        updateGeofencessCount()
    }
    
    func removeAnnotation(_ geofenceAnnotation: GeofenceAnnotation) {
        guard let index = geofences.firstIndex(of: geofenceAnnotation) else { return }
        geofences.remove(at: index)
        mapView.removeAnnotation(geofenceAnnotation)
        removeRadiusOverlay(for: geofenceAnnotation)
        updateGeofencessCount()
    }

    //MARK: - map overlay Methods
    func addRadiusOverlay(for geofenceAnnotation: GeofenceAnnotation) {
        mapView.addOverlay(MKCircle(center: geofenceAnnotation.coordinate, radius: geofenceAnnotation.radius))
    }
    
    func removeRadiusOverlay(for geofenceAnnotation: GeofenceAnnotation) {
        for overlay in mapView.overlays {
            guard let circle = overlay as? MKCircle else { continue }
            let coordinate = circle.coordinate
            if coordinate.latitude == geofenceAnnotation.coordinate.latitude &&
                coordinate.longitude == geofenceAnnotation.coordinate.longitude &&
                circle.radius == geofenceAnnotation.radius {
                mapView.removeOverlay(circle)
                break
            }
        }
    }
    
    func updateGeofencessCount() {
      title = "Geotifications: \(geofences.count)"
    }
    
    //MARK: - IBAction
    @IBAction func zoomButtonTapped(_ sender: Any) {
        mapView.centerToUserLocation()
    }
    
    //MARK: - other related Methods
    func addGeotificationViewController( didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geofence = GeofenceAnnotation(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        addAnnotation(geofence)
        startMonitoring(geofenceAnnotation: geofence)
//        saveAllGeofenceAnnotations()
    }
    
    func region(with geofenceAnnotation: GeofenceAnnotation) -> CLCircularRegion {
        let region = CLCircularRegion(center: geofenceAnnotation.coordinate, radius: geofenceAnnotation.radius, identifier: geofenceAnnotation.identifier)
        region.notifyOnEntry = (geofenceAnnotation.eventType == .beEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
      
    func startMonitoring(geofenceAnnotation: GeofenceAnnotation) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(with:"Error", and: "Geofencing is not supported on this device!")
          return
        }

        if CLLocationManager.authorizationStatus() != .authorizedAlways {
          let message = """
          Your geofence is saved but will only be activated once you grant
          region monitor has the permission to access the device location.
          """
            showAlert(with:"Warning", and: message)
        }

        let fenceRegion = region(with: geofenceAnnotation)
        locationManager.startMonitoring(for: fenceRegion)
//        locationManager.requestState(for: fenceRegion)
    }

    func stopMonitoring(geofenceAnnotation: GeofenceAnnotation) {
        for region in locationManager.monitoredRegions {
          guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geofenceAnnotation.identifier else { continue }
          locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func handleEvent(for region: CLRegion!) {
        guard let message = note(from: region.identifier) else { return }
        
        let content = UNMutableNotificationContent()
        content.body = message
        content.sound = UNNotificationSound.default
        content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "location_change",
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
        
        showAlert(with: nil, and: message)
    }
    
    func note(from identifier: String) -> String? {
        let geofence = geofences
        guard let matched = geofence.filter({
            $0.identifier == identifier
        }).first else { return nil }
        return matched.note
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            print("Approved")
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(for: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(for: region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      let identifier = "myGeotification"
      if annotation is GeofenceAnnotation {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        if annotationView == nil {
          annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
          annotationView?.canShowCallout = true
          let removeButton = UIButton(type: .custom)
          removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
          removeButton.setImage(UIImage(systemName: "multiply.circle")!, for: .normal)
          annotationView?.leftCalloutAccessoryView = removeButton
        } else {
          annotationView?.annotation = annotation
        }
        return annotationView
      }
      return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if overlay is MKCircle {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = .purple
        circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
        return circleRenderer
      }
      return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete geotification
        let geoAnnotation = view.annotation as! GeofenceAnnotation
        stopMonitoring(geofenceAnnotation: geoAnnotation)
        removeAnnotation(geoAnnotation)
        saveAllGeofenceAnnotations()
    }
}

extension ViewController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
