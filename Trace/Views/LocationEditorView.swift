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
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Binding var locationName: String?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var isSaving = false
    
    init(latitude: Binding<Double?>, longitude: Binding<Double?>, locationName: Binding<String?>) {
        self._latitude = latitude
        self._longitude = longitude
        self._locationName = locationName
        
        let initialLat = latitude.wrappedValue ?? 37.7749
        let initialLon = longitude.wrappedValue ?? -122.4194
        let coord = CLLocationCoordinate2D(latitude: initialLat, longitude: initialLon)
        
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
                            let name = await LocationManager.reverseGeocode(selectedCoordinate)
                            
                            latitude = selectedCoordinate.latitude
                            longitude = selectedCoordinate.longitude
                            locationName = name
                            
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
    LocationEditorView(latitude: .constant(37.7749), longitude: .constant(-122.4194), locationName: .constant("San Francisco"))
}
