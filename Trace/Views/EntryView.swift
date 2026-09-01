//
//  EntryView.swift
//  Trace
//
//  Created by Kayden Wang on 2/2/26.
//

import SwiftUI
import SwiftData
import MapKit

private struct LabeledValue<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

struct EntryView: View {
    
    @Bindable var entry: Entry
    var customTitle: String? = nil
    @State private var showingSheet = false
    
    var body: some View {
        List() {
            LabeledValue(title: "Timestamp") {
                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.body)
            }
            
            LabeledValue(title: "Rating") {
                if let rating = entry.rating {
                    Text(rating.formatted())
                        .monospacedDigit()
                } else {
                    Text("No rating")
                        .foregroundStyle(.secondary)
                }
            }
            
            if let data = entry.photoData, let uiImage = UIImage(data: data) {
                LabeledValue(title: "Photo") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            @AppStorage("recordLocation") var recordLocation: Bool = true
            
            if recordLocation {
                if let lat = entry.latitude, let lon = entry.longitude {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    LabeledValue(title: entry.locationName ?? "Location") {
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))) {
                            Marker(entry.locationName ?? "Location", coordinate: coordinate)
                        }
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .allowsHitTesting(false)
                        .mapControlVisibility(.hidden)
                    }
                }
            }
            
            Section("Description") {
                if let desc = entry.desc, !desc.isEmpty {
                    Text(desc)
                        .textSelection(.enabled)
                } else {
                    Text("No description")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(customTitle ?? entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSheet.toggle()
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit entry")
            }
        }
        .sheet(isPresented: $showingSheet) {
            EditEntryView(entry: entry)
        }
    }
}

#Preview {
    EntryView(entry: Entry(timestamp: Date(), title: "", rating: 5))
        .modelContainer(for: Entry.self, inMemory: true)
}
