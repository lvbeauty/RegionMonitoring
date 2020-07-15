//
//  Geofence.swift
//  RegionMonitoring
//
//  Created by Tong Yi on 7/14/20.
//  Copyright © 2020 Tong Yi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

enum EventType: String {
    case beEntry = "Being Entry"
    case beExit = "Being Exit"
}

struct PreferencesKeys {
  static let savedItems = "savedItems"
}

class GeofenceAnnotation: NSObject, Codable, MKAnnotation {
    //MARK: - stored properties
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDegrees
    var identifier: String
    var note: String
    var eventType: EventType
    
    //MARK: - computed property
    var title: String? {
        if note.isEmpty {
            return "No Note"
        }
        
        return note
    }
    
    var subtitle: String? {
        let eventTypeValue = eventType.rawValue
        return "Radius: \(radius)m -> \(eventTypeValue)"
    }
    
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDegrees, identifier: String, note: String, eventType: EventType) {
        self.coordinate = coordinate
        self.radius = radius
        self.identifier = identifier
        self.note = note
        self.eventType = eventType
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, radius, identifier, note, eventType
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try values.decode(Double.self, forKey: .latitude)
        let longitude = try values.decode(Double.self, forKey: .longitude)
        let event = try values.decode(String.self, forKey: .eventType)
        coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        radius = try values.decode(Double.self, forKey: .radius)
        identifier = try values.decode(String.self, forKey: .identifier)
        note = try values.decode(String.self, forKey: .note)
        eventType = EventType(rawValue: event) ?? .beEntry
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(radius, forKey: .radius)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(note, forKey: .note)
        try container.encode(eventType.rawValue, forKey: .eventType)
    }
}

extension GeofenceAnnotation {
    public class func allGeofence() -> [GeofenceAnnotation] {
        guard let savedData = UserDefaults.standard.data(forKey: PreferencesKeys.savedItems) else { return []}
        
        let decoder = JSONDecoder()
        var savedGeofences = [GeofenceAnnotation]()
        
        do {
            savedGeofences = try decoder.decode([GeofenceAnnotation].self, from: savedData)
        } catch {
            print(error.localizedDescription)
        }
        
        return savedGeofences
    }
}
