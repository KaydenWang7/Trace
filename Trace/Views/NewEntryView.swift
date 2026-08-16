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

    @State private var timestamp: Date = Date()
    @State private var title: String = ""
    @State private var rating: Double? = nil
    @State private var desc: String = ""
    @State private var photoData: Data? = nil
    @State private var locationManager = LocationManager()

    var body: some View {
        NavigationStack {
            EntryForm(
                timestamp: $timestamp,
                title: $title,
                rating: $rating,
                desc: $desc,
                photoData: $photoData,
                onChange: {}
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        // Smart fallback: use location name as title only if left blank
                        let finalTitle: String
                        if trimmedTitle.isEmpty {
                            finalTitle = locationManager.locationName ?? "Untitled"
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
                            latitude: locationManager.coordinate?.latitude,
                            longitude: locationManager.coordinate?.longitude,
                            locationName: locationManager.locationName,
                            log: log
                        )
                        modelContext.insert(entry)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.fetchLocation()
            }
        }
    }
}

#Preview {
    NewEntryView(log: Log(title: "Sample Log"))
        .modelContainer(for: [Log.self, Entry.self], inMemory: true)
}


