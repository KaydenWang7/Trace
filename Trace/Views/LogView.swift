//
//  LogView.swift
//  Trace
//
//  Created by Kayden Wang on 4/2/26.
//

import SwiftUI
import SwiftData

struct LogView: View {
    let log: Log
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [Entry]
    @State private var showingNewEntrySheet = false
    @State private var showingRenameSheet = false
    @State private var editedTitle: String = ""
    @AppStorage("showGradient") private var showGradient: Bool = true

    init(log: Log) {
        self.log = log
        let id = log.persistentModelID
        _entries = Query(filter: #Predicate<Entry> { $0.log?.persistentModelID == id }, sort: \Entry.timestamp, order: .reverse)
    }

    var body: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink(destination: EntryView(entry: entry)) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                            Text(entry.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                .foregroundStyle(.secondary)
                            if let desc = entry.desc, !desc.isEmpty {
                                Text(desc)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let rating = entry.rating {
                            Text(rating.formatted())
                                .font(.headline)
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(
                    showGradient ? LinearGradient(colors: rowGradientColors(for: entry.rating), startPoint: .topLeading, endPoint: .bottomTrailing) : nil
                )
            }
            .onDelete(perform: deleteEntries)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    editedTitle = log.title
                    showingRenameSheet = true
                }) {
                    Label("Rename Log", systemImage: "pencil")
                }
            }
            ToolbarItem {
                Button(action: { showingNewEntrySheet = true }) {
                    Label("Add Entry", systemImage: "plus")
                }
            }
        }
        .navigationTitle(log.title)
        .sheet(isPresented: $showingNewEntrySheet) {
            NewEntryView(log: log)
        }
        .sheet(isPresented: $showingRenameSheet) {
            NavigationStack {
                Form {
                    Section("Title") {
                        TextField("Log title", text: $editedTitle)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(false)
                    }
                }
                .navigationTitle("Rename Log")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingRenameSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !newTitle.isEmpty else { return }
                            log.title = newTitle
                            try? modelContext.save()
                            showingRenameSheet = false
                        }
                    }
                }
            }
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
            return [Color(uiColor: .secondarySystemGroupedBackground)]
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
        let base = Color(hue: hue, saturation: 0.80, brightness: 1.0)
        let lighter = Color(hue: hue, saturation: 0.60, brightness: 1.0)
        return [base.opacity(0.30), lighter.opacity(0.22)]
    }
}

#Preview {
    let container = try! ModelContainer(for: Log.self, Entry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let previewLog = Log(title: "Sample Log")
    container.mainContext.insert(previewLog)
    return LogView(log: previewLog)
        .modelContainer(container)
}

