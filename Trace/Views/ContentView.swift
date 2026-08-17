//
//  ContentView.swift
//  Trace
//
//  Created by Kayden Wang on 2/1/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Log.createdAt, order: .reverse) private var logs: [Log]
    
    @State private var showingSettingsSheet = false
    @State private var showingNewLogSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(logs) { log in
                    NavigationLink(log.title) {
                        LogView(log: log)
                    }
                }
                .onDelete(perform: deleteLogs)
            }
            .navigationTitle("All Logs")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        AllEntriesMapView()
                    } label: {
                        Label("Map", systemImage: "map")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewLogSheet = true } label: { Label("Add Log", systemImage: "plus") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettingsSheet = true }) { Label("Settings", systemImage: "gear") }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
            .sheet(isPresented: $showingNewLogSheet) {
                NewLogView { title in
                    let newLog = Log(title: title)
                    modelContext.insert(newLog)
                    try? modelContext.save()
                }
            }
        }
    }
    
    private func deleteLogs(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(logs[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Log.self, Entry.self], inMemory: true)
}
