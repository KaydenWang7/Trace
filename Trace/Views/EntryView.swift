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
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.title)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                .frame(maxWidth:.infinity, alignment: .center)
        }
        .navigationTitle(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
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
    EntryView(entry: Entry(timestamp: Date(), title: ""))
        .modelContainer(for: Entry.self, inMemory: true)
}
