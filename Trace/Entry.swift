//
//  Entry.swift
//  Trace
//
//  Created by Kayden Wang on 2/1/26.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Entry {
    var timestamp: Date = Date()
    var title: String = ""
    var rating: Double?
    var desc: String? = nil
    var photoData: Data? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var locationName: String? = nil
    
    var log: Log?
    
    /// Transient computed property for MapKit integration.
    @Transient
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(timestamp: Date, title: String, rating: Double? = nil, desc: String? = nil, photoData: Data? = nil, latitude: Double? = nil, longitude: Double? = nil, locationName: String? = nil, log: Log? = nil) {
        self.timestamp = timestamp
        self.title = title
        self.rating = rating
        self.desc = desc
        self.photoData = photoData
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.log = log
    }
}
