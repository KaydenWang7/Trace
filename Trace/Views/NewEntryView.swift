//
//  NewEntryView.swift
//  Trace
//
//  Created by Kayden Wang on 2/4/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct NewEntryView: View {
    let log: Log
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ErrorHandler.self) private var errorHandler

    @State private var timestamp: Date = Date()
    @State private var title: String = ""
    @State private var rating: Double? = nil
    @State private var desc: String = ""
    @State private var photoData: Data? = nil
    @State private var locationManager = LocationManager()
    @FocusState private var isTitleFocused: Bool
    
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var locationName: String? = nil
    
    @AppStorage("recordLocation") private var recordLocation: Bool = true

    var body: some View {
        NavigationStack {
            EntryForm(
                timestamp: $timestamp,
                title: $title,
                rating: $rating,
                desc: $desc,
                photoData: $photoData,
                latitude: $latitude,
                longitude: $longitude,
                locationName: $locationName,
                onChange: {},
                titleFocused: $isTitleFocused,
                isNewEntry: true
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                }
            }
            .onAppear {
                if recordLocation {
                    locationManager.requestPermission()
                    locationManager.fetchLocation()
                }
                isTitleFocused = true
            }
            .onChange(of: locationManager.coordinate?.latitude) { _, newLat in
                if latitude == nil {
                    latitude = newLat
                }
            }
            .onChange(of: locationManager.coordinate?.longitude) { _, newLon in
                if longitude == nil {
                    longitude = newLon
                }
            }
            .onChange(of: locationManager.locationName) { _, newName in
                if locationName == nil {
                    locationName = newName
                }
            }
        }
    }
    
    private func saveEntry() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        // Smart fallback: use location name as title only if left blank
        let finalTitle: String
        if trimmedTitle.isEmpty {
            finalTitle = locationName ?? "Untitled"
        } else {
            finalTitle = trimmedTitle
        }
        let trimmedDesc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        let descValue: String? = trimmedDesc.isEmpty ? nil : trimmedDesc
        let entry = Entry(
            timestamp: timestamp,
            title: finalTitle,
            rating: rating,
            desc: descValue,
            photoData: photoData,
            latitude: recordLocation ? latitude : nil,
            longitude: recordLocation ? longitude : nil,
            locationName: recordLocation ? locationName : nil,
            log: log
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
        } catch {
            errorHandler.handle(error)
        }
        
        // Background location processing
        if recordLocation && locationManager.isLoading {
            let manager = locationManager
            let entryID = entry.persistentModelID
            let container = modelContext.container
            let wasUntitled = trimmedTitle.isEmpty
            
            Task.detached {
                let startTime = Date()
                // Wait up to 15 seconds for location
                while await manager.isLoading && Date().timeIntervalSince(startTime) < 15 {
                    try? await Task.sleep(for: .milliseconds(500))
                }
                
                let lat = await manager.coordinate?.latitude
                let lon = await manager.coordinate?.longitude
                let name = await manager.locationName
                
                if lat != nil {
                    let bgContext = ModelContext(container)
                    if let entryToUpdate = bgContext.model(for: entryID) as? Entry {
                        entryToUpdate.latitude = lat
                        entryToUpdate.longitude = lon
                        entryToUpdate.locationName = name
                        
                        if wasUntitled, let newName = name {
                            entryToUpdate.title = newName
                        }
                        
                        try? bgContext.save()
                    }
                }
            }
        }
        
        dismiss()
    }
}

#Preview {
    NewEntryView(log: Log(title: "Sample Log"))
        .modelContainer(for: [Log.self, Entry.self], inMemory: true)
}
