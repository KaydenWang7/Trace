//
//  NewEntryView.swift
//  Trace
//
//  Created by Kayden Wang on 2/4/26.
//

import SwiftUI
import SwiftData

struct NewEntryView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var timestamp: Date = Date()
    @State private var title: String = ""
    @State private var rating: Double? = nil

    var body: some View {
        NavigationStack {
            EntryForm(
                timestamp: $timestamp,
                title: $title,
                rating: $rating,
                onChange: {}
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        let created = Entry(timestamp: timestamp, title: title, rating: rating)
                        modelContext.insert(created)
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "checkmark")
                    }
                }
            }
        }
    }
}
