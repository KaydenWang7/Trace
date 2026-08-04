//
//  EntryView.swift
//  Trace
//
//  Created by Kayden Wang on 2/2/26.
//

import SwiftUI
import SwiftData

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
            Section("Description") {
                Text(entry.desc ?? "")
                    .textSelection(.enabled)
            }
        }
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSheet.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
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
