//
//  AllEntriesMapView.swift
//  Trace
//
//  Created by Kayden Wang on 8/16/26.
//

import SwiftUI
import SwiftData
import MapKit

struct AllEntriesMapView: View {
    @Query(sort: \Log.createdAt, order: .reverse) private var logs: [Log]
    @Query(sort: \Entry.timestamp, order: .reverse) private var allEntries: [Entry]
    
    @State private var selectedLogID: PersistentIdentifier?
    @State private var selectedEntry: Entry?
    
    /// Entries filtered by the current picker selection, with valid coordinates only.
    private var displayedEntries: [Entry] {
        let source: [Entry]
        if let selectedLogID,
           let log = logs.first(where: { $0.persistentModelID == selectedLogID }) {
            source = log.entries
        } else {
            source = allEntries
        }
        return source.filter { $0.latitude != nil && $0.longitude != nil }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(selection: $selectedEntry) {
                ForEach(displayedEntries) { entry in
                    if let lat = entry.latitude, let lon = entry.longitude {
                        Marker(
                            entry.title,
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        )
                        .tag(entry)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)
            
            // Filter picker
            filterPicker
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                EntryView(entry: entry)
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private var filterPicker: some View {
        Menu {
            Button {
                selectedLogID = nil
            } label: {
                if selectedLogID == nil {
                    Label("All Entries", systemImage: "checkmark")
                } else {
                    Text("All Entries")
                }
            }
            
            if !logs.isEmpty {
                Divider()
            }
            
            ForEach(logs) { log in
                Button {
                    selectedLogID = log.persistentModelID
                } label: {
                    if selectedLogID == log.persistentModelID {
                        Label(log.title, systemImage: "checkmark")
                    } else {
                        Text(log.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.subheadline.weight(.semibold))
                Text(filterLabel)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
        }
        .padding(.top, 8)
    }
    
    private var filterLabel: String {
        if let selectedLogID,
           let log = logs.first(where: { $0.persistentModelID == selectedLogID }) {
            return log.title
        }
        return "All Entries"
    }
}

#Preview {
    NavigationStack {
        AllEntriesMapView()
    }
    .modelContainer(for: [Log.self, Entry.self], inMemory: true)
}
