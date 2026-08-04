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
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var timestamp: Date = Date()
    @State private var title: String = ""
    @State private var rating: Double? = nil
    @State private var desc: String = ""
    @State private var photoData: Data? = nil

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
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        let created = Entry(timestamp: timestamp, title: title.isEmpty ? "Untitled" : title, rating: rating, desc: desc.isEmpty ? nil : desc, photoData: photoData)
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

