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

@Observable @MainActor
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
    
    /// Fast location fetch.
    func fetchLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        isLoading = true
        manager.startUpdatingLocation()
    }
    
    /// Reverse-geocode an arbitrary coordinate using MKReverseGeocodingRequest.
    nonisolated static func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String? {
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
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let location = locations.first else {
            Task { @MainActor in self.isLoading = false }
            return
        }
        
        Task { @MainActor in
            self.coordinate = location.coordinate
            
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
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location fetch failed: \(error.localizedDescription)")
        Task { @MainActor in self.isLoading = false }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            // Auto-fetch once authorized
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.fetchLocation()
            }
        }
    }
}
