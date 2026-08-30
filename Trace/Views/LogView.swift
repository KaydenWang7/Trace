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
    @Environment(ErrorHandler.self) private var errorHandler
    @Query private var entries: [Entry]
    @State private var showingNewEntrySheet = false
    @State private var showingEditSheet = false
    @State private var showingStatsSheet = false
    @State private var editedTitle: String = ""
    @State private var editedIcon: String = "book.closed"
    @State private var editedColor: String = "blue"
    @State private var selectedEntries = Set<PersistentIdentifier>()
    @State private var showingDeleteConfirmation = false
    @State private var editMode: EditMode = .inactive
    @AppStorage("showGradient") private var showGradient: Bool = true

    init(log: Log) {
        self.log = log
        let id = log.persistentModelID
        _entries = Query(filter: #Predicate<Entry> { $0.log?.persistentModelID == id }, sort: \Entry.timestamp, order: .reverse)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List(selection: $selectedEntries) {
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
            }
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingStatsSheet = true }) {
                        Label("Statistics", systemImage: "chart.bar")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        editedTitle = log.title
                        editedIcon = log.icon
                        editedColor = log.iconColor
                        showingEditSheet = true
                    }) {
                        Label("Edit Log", systemImage: "pencil")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            if editMode == .active {
                                editMode = .inactive
                                selectedEntries.removeAll()
                            } else {
                                editMode = .active
                            }
                        }
                    } label: {
                        Image(systemName: editMode == .active ? "checkmark.circle.fill" : "checkmark.circle")
                    }
                }
                if editMode == .active && !selectedEntries.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedEntries.count) Entr\(selectedEntries.count == 1 ? "y" : "ies")?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteSelectedEntries()
                }
            } message: {
                Text("\(selectedEntries.count == 1 ? "This entry" : "These entries") will be permanently deleted. This action cannot be undone.")
            }
            .navigationTitle(log.title)
            .sheet(isPresented: $showingNewEntrySheet) {
                NewEntryView(log: log)
            }
            .sheet(isPresented: $showingStatsSheet) {
                LogStatsView(entries: entries)
            }
            .sheet(isPresented: $showingEditSheet) {
                NavigationStack {
                    Form {
                        Section {
                            HStack {
                                Image(systemName: editedIcon)
                                    .font(.title3)
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(LogTheme.color(for: editedColor), in: RoundedRectangle(cornerRadius: 8))
                                TextField("Log title", text: $editedTitle)
                                    .textInputAutocapitalization(.words)
                                    .disableAutocorrection(false)
                            }
                        }
                        
                        LogIconPickerSections(selectedIcon: $editedIcon, selectedColor: $editedColor)
                    }
                    .navigationTitle("Edit Log")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingEditSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let newTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !newTitle.isEmpty else { return }
                                log.title = newTitle
                                log.icon = editedIcon
                                log.iconColor = editedColor
                                do {
                                    try modelContext.save()
                                } catch {
                                    errorHandler.handle(error)
                                }
                                showingEditSheet = false
                            }
                        }
                    }
                }
            }
            
            // Floating add button — liquid glass
            if editMode == .inactive {
                Button {
                    showingNewEntrySheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 56, height: 56)
                }
                .glassEffect(.regular, in: .circle)
                .shadow(radius: 4, y: 2)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .accessibilityLabel("Add new entry")
            }
        }
    }

    private func deleteSelectedEntries() {
        withAnimation {
            for entry in entries where selectedEntries.contains(entry.persistentModelID) {
                modelContext.delete(entry)
            }
            do {
                try modelContext.save()
            } catch {
                errorHandler.handle(error)
            }
            selectedEntries.removeAll()
            editMode = .inactive
        }
    }
    
    private func rowGradientColors(for rating: Double?) -> [Color] {
        guard let rating = rating else {
            // No rating: subtle gray gradient
            return [Color(uiColor: .secondarySystemGroupedBackground)]
        }
        let hue = LogTheme.ratingHue(for: rating)
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
