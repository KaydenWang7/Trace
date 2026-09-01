//
//  PhotoGalleryView.swift
//  Trace
//
//  Created by Kayden Wang on 8/30/26.
//

import SwiftUI
import SwiftData

struct PhotoGalleryView: View {
    var initialLogID: PersistentIdentifier? = nil
    
    @Query(sort: \Log.createdAt, order: .reverse) private var logs: [Log]
    @Query(sort: \Entry.timestamp, order: .reverse) private var allEntries: [Entry]
    
    @State private var selectedLogID: PersistentIdentifier?
    @State private var selectedEntry: Entry?
    @State private var hasAppliedInitialFilter = false
    
    /// Entries filtered by the current picker selection, with photos only.
    private var displayedEntries: [Entry] {
        let source: [Entry]
        if let selectedLogID,
           let log = logs.first(where: { $0.persistentModelID == selectedLogID }) {
            source = (log.entries ?? []).sorted { $0.timestamp > $1.timestamp }
        } else {
            source = allEntries
        }
        return source.filter { $0.photoData != nil }
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 3)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            if displayedEntries.isEmpty {
                ContentUnavailableView(
                    "No Photos",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Entries with photos will appear here.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 3) {
                        ForEach(displayedEntries) { entry in
                            if let data = entry.photoData, let uiImage = UIImage(data: data) {
                                Button {
                                    selectedEntry = entry
                                } label: {
                                    Color.clear
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                        )
                                        .clipped()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 52) // space for the filter pill
                    .padding(.horizontal, 1)
                }
            }
            
            // Filter picker
            filterPicker
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !hasAppliedInitialFilter {
                selectedLogID = initialLogID
                hasAppliedInitialFilter = true
            }
        }
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                EntryView(
                    entry: entry,
                    customTitle: entry.log != nil ? "\(entry.log!.title) / \(entry.title)" : entry.title
                )
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
        PhotoGalleryView()
    }
    .modelContainer(for: [Log.self, Entry.self], inMemory: true)
}
