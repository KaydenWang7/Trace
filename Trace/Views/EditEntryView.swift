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
    @State private var showDiscardDialog = false
    @State private var showSaveDialog = false
    @State private var hasChanges = false
    @State private var draftTimestamp: Date
    @State private var draftTitle: String = ""
    @State private var draftRating: Double? = nil
    @State private var draftDesc: String = ""
    
    init(entry: Entry) {
        self.entry = entry
        _draftTimestamp = State(initialValue: entry.timestamp)
        _draftTitle = State(initialValue: entry.title)
        _draftRating = State(initialValue: entry.rating)
        _draftDesc = State(initialValue: entry.desc ?? "")
    }
    
    var body: some View {
        NavigationStack {
            EntryForm(
                timestamp: $draftTimestamp,
                title: $draftTitle,
                rating: $draftRating,
                desc: $draftDesc,
                onChange: { hasChanges = true }
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
                    Button("Done", systemImage: "checkmark", role: .confirm) {
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
                Button("Save", role: .confirm) {
                    entry.timestamp = draftTimestamp
                    entry.title = draftTitle
                    entry.rating = draftRating
                    entry.desc = draftDesc.isEmpty ? nil : draftDesc
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

