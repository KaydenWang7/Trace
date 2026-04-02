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
    @Query private var entries: [Entry]
    @State private var showingNewEntrySheet = false
    @State private var showingSettingsSheet = false
    @AppStorage("showGradient") private var showGradient: Bool = true

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(entries) { entry in
                    NavigationLink(destination: EntryView(entry: entry)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title)
                                Text(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let rating = entry.rating {
                                Text(rating.formatted())
                            } else {
                                Text("")
                            }
                        }
                    }
                    .if(showGradient) { view in
                        view.listRowBackground(
                            LinearGradient(
                                colors: rowGradientColors(for: entry.rating),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettingsSheet = true }) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem {
                    Button(action: { showingNewEntrySheet = true }) {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an entry")
        }
        .sheet(isPresented: $showingNewEntrySheet) {
            NewEntryView()
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
    
    private func rowGradientColors(for rating: Double?) -> [Color] {
        guard let rating = rating else {
            // No rating: subtle gray gradient
            return [Color.gray.opacity(0.15), Color.gray.opacity(0.10)]
        }
        // Clamp rating between 0 and 10
        let clamped = max(0, min(10, rating))
        // Map 0..10 to hue with 0 = red, 5 = yellow, 10 = green using easing and piecewise interpolation
        let t = Double(clamped) / 10.0
        // Piecewise interpolate hue: 0.0 (red) -> 0.16 (yellow) -> 0.33 (green)
        let hue: Double
        if t <= 0.5 {
            // Map 0..0.5 to red..yellow
            let local = t / 0.5 // 0..1
            hue = 0.0 + (0.16 - 0.0) * local
        } else {
            // Map 0.5..1.0 to yellow..green
            let local = (t - 0.5) / 0.5 // 0..1
            hue = 0.16 + (0.33 - 0.16) * local
        }
        let base = Color(hue: hue, saturation: 0.65, brightness: 0.95)
        let lighter = Color(hue: hue, saturation: 0.45, brightness: 1.0)
        return [base.opacity(0.30), lighter.opacity(0.22)]
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Entry.self, inMemory: true)
}
