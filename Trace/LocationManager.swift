//
//  LocationManager.swift
//  Trace
//
//  Created by Kayden Wang on 8/6/26.
//

import Foundation
import CoreLocation
import MapKit
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var coordinate: CLLocationCoordinate2D?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus
    var isLoading: Bool = false
    
    private let manager = CLLocationManager()
    
    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Public API
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Single-shot location fetch — battery efficient.
    func fetchLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        isLoading = true
        manager.requestLocation()
    }
    
    /// Reverse-geocode an arbitrary coordinate using MKReverseGeocodingRequest.
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        do {
            let mapItems = try await request.mapItems
            return mapItems.first?.name
        } catch {
            print("Reverse geocoding failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            isLoading = false
            return
        }
        
        coordinate = location.coordinate
        
        Task { @MainActor in
            if let request = MKReverseGeocodingRequest(location: location) {
                do {
                    let mapItems = try await request.mapItems
                    if let mapItem = mapItems.first {
                        self.locationName = mapItem.name
                    }
                } catch {
                    print("Reverse geocoding failed: \(error.localizedDescription)")
                }
            }
            self.isLoading = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location fetch failed: \(error.localizedDescription)")
        isLoading = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        // Auto-fetch once authorized
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            fetchLocation()
        }
    }
}

