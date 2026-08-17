//
//  LocationEditorView.swift
//  Trace
//
//  Created by Kayden Wang on 8/6/26.
//

import SwiftUI
import SwiftData
import MapKit

struct LocationEditorView: View {
    @Bindable var entry: Entry
    @Environment(\.dismiss) private var dismiss
    
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var isSaving = false
    
    init(entry: Entry) {
        self.entry = entry
        let coord = entry.coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default to SF
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
        _selectedCoordinate = State(initialValue: coord)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {}
                    .onMapCameraChange(frequency: .onEnd) { context in
                        selectedCoordinate = context.camera.centerCoordinate
                    }
                    .ignoresSafeArea(edges: .bottom)
                
                // Fixed pin overlay
                VStack {
                    Image(systemName: "mappin")
                        .font(.system(size: 36))
                        .foregroundStyle(.red)
                        .shadow(radius: 3)
                    // Offset so the pin tip is at center
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.red.opacity(0.5))
                }
                .allowsHitTesting(false)
            }
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isSaving = true
                        Task {
                            // Reverse-geocode the new coordinate
                            let locationManager = LocationManager()
                            let name = await locationManager.reverseGeocode(selectedCoordinate)
                            
                            entry.latitude = selectedCoordinate.latitude
                            entry.longitude = selectedCoordinate.longitude
                            entry.locationName = name
                            
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
}

#Preview {
    LocationEditorView(entry: Entry(timestamp: Date(), title: "Sample", latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco"))
        .modelContainer(for: Entry.self, inMemory: true)
}
