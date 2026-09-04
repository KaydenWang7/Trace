//
//  EditEntryView.swift
//  Trace
//
//  Created by Kayden Wang on 2/2/26.
//

import SwiftUI
import SwiftData

struct EditEntryView: View {
    
    @Bindable var entry: Entry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ErrorHandler.self) private var errorHandler
    @State private var showDiscardDialog = false
    @State private var showSaveDialog = false
    @State private var hasChanges = false
    @State private var draftTimestamp: Date
    @State private var draftTitle: String = ""
    @State private var draftRating: Double? = nil
    @State private var draftDesc: String = ""
    @State private var draftPhotoData: Data? = nil
    @State private var draftLatitude: Double? = nil
    @State private var draftLongitude: Double? = nil
    @State private var draftLocationName: String? = nil
    
    init(entry: Entry) {
        self.entry = entry
        _draftTimestamp = State(initialValue: entry.timestamp)
        _draftTitle = State(initialValue: entry.title)
        _draftRating = State(initialValue: entry.rating)
        _draftDesc = State(initialValue: entry.desc ?? "")
        _draftPhotoData = State(initialValue: entry.photoData)
        _draftLatitude = State(initialValue: entry.latitude)
        _draftLongitude = State(initialValue: entry.longitude)
        _draftLocationName = State(initialValue: entry.locationName)
    }
    
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        NavigationStack {
            EntryForm(
                timestamp: $draftTimestamp,
                title: $draftTitle,
                rating: $draftRating,
                desc: $draftDesc,
                photoData: $draftPhotoData,
                latitude: $draftLatitude,
                longitude: $draftLongitude,
                locationName: $draftLocationName,
                onChange: { hasChanges = true },
                titleFocused: $isTitleFocused
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        if hasChanges {
                            showDiscardDialog = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        if hasChanges {
                            showSaveDialog = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .confirmationDialog(
                "Discard Changes?",
                isPresented: $showDiscardDialog,
                titleVisibility: .visible
            ) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .confirmationDialog(
                "Save Changes?",
                isPresented: $showSaveDialog,
                titleVisibility: .visible
            ) {
                Button("Save") {
                    entry.timestamp = draftTimestamp
                    let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    entry.title = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle
                    entry.rating = draftRating
                    let trimmedDesc = draftDesc.trimmingCharacters(in: .whitespacesAndNewlines)
                    entry.desc = trimmedDesc.isEmpty ? nil : trimmedDesc
                    entry.photoData = draftPhotoData
                    entry.latitude = draftLatitude
                    entry.longitude = draftLongitude
                    entry.locationName = draftLocationName
                    do {
                        try modelContext.save()
                    } catch {
                        errorHandler.handle(error)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Do you want to save your edits?")
            }
        }
    }
}

#Preview {
    EditEntryView(entry: Entry(timestamp: Date(), title: "", rating: 5))
        .modelContainer(for: Entry.self, inMemory: true)
}
