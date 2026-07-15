//
//  EntryView.swift
//  Trace
//
//  Created by Kayden Wang on 2/2/26.
//

import SwiftUI
import SwiftData

struct EntryView: View {
    
    @Bindable var entry: Entry
    @State private var showingSheet = false
    
    var body: some View {
        List() {
            VStack(alignment: .leading) {
                Text("Timestamp")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.body)
            }
            
            if let rating = entry.rating {
                VStack(alignment: .leading) {
                    Text("Rating")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(rating.formatted()))
                }
            } else {
                VStack(alignment: .leading) {
                    Text("Rating")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("No rating")
                }
            }
            Section("Description") {
                Text(entry.desc ?? "")
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
