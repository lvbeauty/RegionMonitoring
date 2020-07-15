//
//  Utilities.swift
//  RegionMonitoring
//
//  Created by Tong Yi on 7/14/20.
//  Copyright © 2020 Tong Yi. All rights reserved.
//

import UIKit
import MapKit

extension UIViewController {
    func showAlert(with title: String?, and message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let oKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(oKAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension MKMapView {
    func centerToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        setRegion(region, animated: true)
    }
}
