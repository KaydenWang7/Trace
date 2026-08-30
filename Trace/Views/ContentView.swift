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
    @Environment(ErrorHandler.self) private var errorHandler
    @Query(sort: \Log.createdAt, order: .reverse) private var logs: [Log]
    
    @AppStorage("recordLocation") private var recordLocation: Bool = true
    
    @State private var showingSettingsSheet = false
    @State private var showingNewLogSheet = false
    @State private var quickAddLog: Log? = nil
    @State private var selectedLogs = Set<PersistentIdentifier>()
    @State private var showingDeleteConfirmation = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List(selection: $selectedLogs) {
                    ForEach(logs) { log in
                        NavigationLink(destination: LogView(log: log)) {
                            HStack(spacing: 12) {
                                // Icon with coloured background
                                Image(systemName: log.icon)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .frame(width: 34, height: 34)
                                    .background(LogTheme.color(for: log.iconColor), in: RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.title)
                                    Text(timeSinceLastEntry(log: log))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                quickAddLog = log
                            } label: {
                                Label("Add", systemImage: "plus.circle.fill")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .navigationTitle("All Logs")
                .environment(\.editMode, $editMode)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if recordLocation {
                            NavigationLink {
                                AllEntriesMapView()
                            } label: {
                                Label("Map", systemImage: "map")
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                if editMode == .active {
                                    editMode = .inactive
                                    selectedLogs.removeAll()
                                } else {
                                    editMode = .active
                                }
                            }
                        } label: {
                            Image(systemName: editMode == .active ? "checkmark.circle.fill" : "checkmark.circle")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingSettingsSheet = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    if editMode == .active && !selectedLogs.isEmpty {
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
                    "Delete \(selectedLogs.count) Log\(selectedLogs.count == 1 ? "" : "s")?",
                    isPresented: $showingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        deleteSelectedLogs()
                    }
                } message: {
                    Text("All entries inside \(selectedLogs.count == 1 ? "this log" : "these logs") will also be permanently deleted. This action cannot be undone.")
                }
                .sheet(isPresented: $showingSettingsSheet) {
                    SettingsView()
                }
                .sheet(isPresented: $showingNewLogSheet) {
                    NewLogView { title, icon, iconColor in
                        let newLog = Log(title: title, icon: icon, iconColor: iconColor)
                        modelContext.insert(newLog)
                        do {
                            try modelContext.save()
                        } catch {
                            errorHandler.handle(error)
                        }
                    }
                }
                .sheet(item: $quickAddLog) { log in
                    NewEntryView(log: log)
                }
                
                // Floating add button — liquid glass
                if editMode == .inactive {
                    Button {
                        showingNewLogSheet = true
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
                    .accessibilityLabel("Create new log")
                }
            }
        }
    }
    
    private func deleteSelectedLogs() {
        withAnimation {
            for log in logs where selectedLogs.contains(log.persistentModelID) {
                modelContext.delete(log)
            }
            do {
                try modelContext.save()
            } catch {
                errorHandler.handle(error)
            }
            selectedLogs.removeAll()
            editMode = .inactive
        }
    }
    
    /// Returns a two-unit relative time string like "3h 42m ago" from the
    /// most recent entry in the log's entries array.
    private func timeSinceLastEntry(log: Log) -> String {
        guard let latest = log.entries.max(by: { $0.timestamp < $1.timestamp }) else {
            return "No entries"
        }
        let interval = Date.now.timeIntervalSince(latest.timestamp)
        guard interval >= 0 else { return "Just now" }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: latest.timestamp, to: .now)
        let months = components.month ?? 0
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0
        
        if months > 0 {
            return days > 0 ? "\(months)mo \(days)d ago" : "\(months)mo ago"
        } else if days >= 7 {
            let weeks = days / 7
            let remainingDays = days % 7
            return remainingDays > 0 ? "\(weeks)w \(remainingDays)d ago" : "\(weeks)w ago"
        } else if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h ago" : "\(days)d ago"
        } else if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m ago" : "\(hours)h ago"
        } else if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s ago" : "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Log.self, Entry.self], inMemory: true)
}
