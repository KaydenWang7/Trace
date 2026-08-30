//
//  LogStatsView.swift
//  Trace
//
//  Created by Kayden Wang on 8/17/26.
//

import SwiftUI
import Charts

// MARK: - Pure statistics computation

/// Lightweight value type that pre-computes every statistic from an array of
/// entries. No model-context dependency—everything derived from `[Entry]`.
private struct LogStatistics {

    // MARK: Overview
    let totalEntries: Int
    let firstEntryDate: Date?
    let lastEntryDate: Date?
    let entriesWithRatings: Int
    let entriesWithPhotos: Int
    let entriesWithLocations: Int

    // MARK: Frequency — raw per-year data for the view to slice
    let entriesPerYear: [(label: String, count: Int)]
    /// Sorted list of years that contain at least one entry.
    let availableYears: [Int]
    /// year → month(1-12) → count
    let monthCounts: [Int: [Int: Int]]
    /// year → weekOfYear(1-53) → count
    let weekCounts: [Int: [Int: Int]]
    /// year → weekday-index(0=Mon…6=Sun) → count
    let dayCounts: [Int: [Int: Int]]

    // MARK: Timing
    let averageGap: TimeInterval?
    let medianGap: TimeInterval?
    let shortestGap: TimeInterval?
    let longestGap: TimeInterval?

    // MARK: Ratings
    let averageRating: Double?
    let highestRating: Double?
    let lowestRating: Double?
    /// Buckets: 0–1, 1–2, …, 9–10. Each element is the count in that bucket.
    let ratingDistribution: [Int]

    // MARK: Init

    init(entries: [Entry]) {
        let sorted = entries.sorted { $0.timestamp < $1.timestamp }

        totalEntries = sorted.count
        firstEntryDate = sorted.first?.timestamp
        lastEntryDate = sorted.last?.timestamp
        entriesWithRatings = sorted.filter { $0.rating != nil }.count
        entriesWithPhotos = sorted.filter { $0.photoData != nil }.count
        entriesWithLocations = sorted.filter { $0.latitude != nil && $0.longitude != nil }.count

        let calendar = Calendar.current

        // ── Year totals ──

        var yearTotals: [Int: Int] = [:]
        for entry in sorted {
            let y = calendar.component(.year, from: entry.timestamp)
            yearTotals[y, default: 0] += 1
        }
        entriesPerYear = yearTotals.sorted { $0.key < $1.key }
            .map { (label: String($0.key), count: $0.value) }
        availableYears = yearTotals.keys.sorted()

        // ── Month (per year) ──

        var mc: [Int: [Int: Int]] = [:]
        for entry in sorted {
            let y = calendar.component(.year, from: entry.timestamp)
            let m = calendar.component(.month, from: entry.timestamp)
            mc[y, default: [:]][m, default: 0] += 1
        }
        monthCounts = mc

        // ── Week of year (per year) ──

        var wc: [Int: [Int: Int]] = [:]
        for entry in sorted {
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.timestamp)
            let y = comps.yearForWeekOfYear!
            let w = comps.weekOfYear!
            wc[y, default: [:]][w, default: 0] += 1
        }
        weekCounts = wc

        // ── Day of week (per year) ──

        var dc: [Int: [Int: Int]] = [:]
        for entry in sorted {
            let y = calendar.component(.year, from: entry.timestamp)
            let wd = calendar.component(.weekday, from: entry.timestamp)
            let index = (wd + 5) % 7  // Sun(1)→6, Mon(2)→0, … Sat(7)→5
            dc[y, default: [:]][index, default: 0] += 1
        }
        dayCounts = dc

        // ── Timing gaps ──

        if sorted.count >= 2 {
            var gaps: [TimeInterval] = []
            gaps.reserveCapacity(sorted.count - 1)
            for i in 1..<sorted.count {
                gaps.append(sorted[i].timestamp.timeIntervalSince(sorted[i - 1].timestamp))
            }
            let sortedGaps = gaps.sorted()
            averageGap = sortedGaps.reduce(0, +) / Double(sortedGaps.count)
            shortestGap = sortedGaps.first
            longestGap = sortedGaps.last
            let mid = sortedGaps.count / 2
            medianGap = sortedGaps.count.isMultiple(of: 2)
                ? (sortedGaps[mid - 1] + sortedGaps[mid]) / 2
                : sortedGaps[mid]
        } else {
            averageGap = nil
            medianGap = nil
            shortestGap = nil
            longestGap = nil
        }

        // ── Ratings ──

        let ratings = sorted.compactMap(\.rating)
        if ratings.isEmpty {
            averageRating = nil
            highestRating = nil
            lowestRating = nil
            ratingDistribution = Array(repeating: 0, count: 11)
        } else {
            averageRating = ratings.reduce(0, +) / Double(ratings.count)
            highestRating = ratings.max()
            lowestRating = ratings.min()
            var dist = Array(repeating: 0, count: 11)
            for r in ratings {
                let bucket = min(max(Int(r.rounded()), 0), 10)
                dist[bucket] += 1
            }
            ratingDistribution = dist
        }
    }

    // MARK: - Per-year chart data builders

    /// Jan–Dec for a given year, always 12 bars.
    func monthData(for year: Int) -> [(label: String, count: Int)] {
        let symbols = DateFormatter().shortMonthSymbols!
        return (1...12).map { m in
            (label: symbols[m - 1], count: monthCounts[year]?[m] ?? 0)
        }
    }

    /// W1–W52/53 for a given year.
    func weekData(for year: Int) -> [(label: String, count: Int)] {
        let calendar = Calendar.current
        let dec31 = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        let maxWeek = calendar.component(.weekOfYear, from: dec31)
        let totalWeeks = maxWeek == 1
            ? calendar.component(.weekOfYear, from: calendar.date(byAdding: .day, value: -7, to: dec31)!)
            : maxWeek
        return (1...totalWeeks).map { w in
            (label: "W\(w)", count: weekCounts[year]?[w] ?? 0)
        }
    }

    /// Mon–Sun for a given year, always 7 bars. Uses unique full names.
    func dayData(for year: Int) -> [(label: String, count: Int)] {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return dayNames.enumerated().map { i, name in
            (label: name, count: dayCounts[year]?[i] ?? 0)
        }
    }
}

// MARK: - Frequency Mode

private enum FrequencyMode: String, CaseIterable, Identifiable {
    case yearly = "Yearly"
    case monthly = "Monthly"
    case weekly = "Weekly"
    case daily = "Daily"

    var id: String { rawValue }

    /// Whether this mode supports swiping between years.
    var supportsYearNavigation: Bool {
        self != .yearly
    }
}

// MARK: - View

struct LogStatsView: View {
    let entries: [Entry]
    @Environment(\.dismiss) private var dismiss
    @State private var frequencyMode: FrequencyMode = .monthly
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var stats: LogStatistics?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries Yet",
                        systemImage: "chart.bar",
                        description: Text("Add entries to this log to see statistics.")
                    )
                } else if let s = stats {
                    statsList(s)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                stats = LogStatistics(entries: entries)
            }
            .onChange(of: entries.count) {
                stats = LogStatistics(entries: entries)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func statsList(_ s: LogStatistics) -> some View {
        List {
            overviewSection(s)
            timingSection(s)
            ratingsSection(s)
            frequencySection(s)
        }
        .onAppear {
            // Default to the most recent year with data
            if let latest = s.availableYears.last {
                selectedYear = latest
            }
        }
    }

    // MARK: Overview

    @ViewBuilder
    private func overviewSection(_ s: LogStatistics) -> some View {
        Section {
            statRow("Total Entries", icon: "list.bullet", value: "\(s.totalEntries)")
            if let first = s.firstEntryDate, let last = s.lastEntryDate {
                HStack {
                    Label("Date Range", systemImage: "calendar")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(first.formatted(date: .numeric, time: .omitted)) – \(last.formatted(date: .numeric, time: .omitted))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        
                        let start = Calendar.current.startOfDay(for: first)
                        let end = Calendar.current.startOfDay(for: last)
                        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
                        Text("\(days + 1) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            statRow("With Ratings", icon: "star", value: "\(s.entriesWithRatings) / \(s.totalEntries)")
            statRow("With Photos", icon: "photo", value: "\(s.entriesWithPhotos) / \(s.totalEntries)")
            statRow("With Locations", icon: "location", value: "\(s.entriesWithLocations) / \(s.totalEntries)")
        } header: {
            Label("Overview", systemImage: "info.circle")
        }
    }

    // MARK: Timing

    @ViewBuilder
    private func timingSection(_ s: LogStatistics) -> some View {
        if let avg = s.averageGap {
            Section {
                statRow("Average", icon: "clock", value: formattedDuration(avg))
                if let med = s.medianGap {
                    statRow("Median", icon: "equal.circle", value: formattedDuration(med))
                }
                if let shortest = s.shortestGap {
                    statRow("Shortest", icon: "hare", value: formattedDuration(shortest))
                }
                if let longest = s.longestGap {
                    statRow("Longest", icon: "tortoise", value: formattedDuration(longest))
                }
            } header: {
                Label("Time Between Entries", systemImage: "clock.arrow.2.circlepath")
            }
        }
    }

    // MARK: Ratings

    @ViewBuilder
    private func ratingsSection(_ s: LogStatistics) -> some View {
        if let avg = s.averageRating {
            Section {
                statRow("Average", icon: "star.leadinghalf.filled", value: String(format: "%.1f", avg))
                if let hi = s.highestRating {
                    statRow("Highest", icon: "arrow.up", value: hi.formatted())
                }
                if let lo = s.lowestRating {
                    statRow("Lowest", icon: "arrow.down", value: lo.formatted())
                }

                // Distribution chart
                Chart {
                    ForEach(0..<11, id: \.self) { bucket in
                        BarMark(
                            x: .value("Rating", String(bucket)),
                            y: .value("Count", s.ratingDistribution[bucket]),
                            width: .ratio(0.8)
                        )
                        .foregroundStyle(barColor(for: bucket))
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
            } header: {
                Label("Ratings", systemImage: "star")
            }
        }
    }

    // MARK: Frequency

    /// Single-letter display labels for days of the week.
    private static let dayShortLabels: [String: String] = [
        "Mon": "M", "Tue": "T", "Wed": "W", "Thu": "T",
        "Fri": "F", "Sat": "S", "Sun": "S"
    ]

    @ViewBuilder
    private func frequencySection(_ s: LogStatistics) -> some View {
        Section {
            Picker("Period", selection: $frequencyMode) {
                ForEach(FrequencyMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Year navigation header (for non-yearly modes)
            if frequencyMode.supportsYearNavigation {
                HStack {
                    Button {
                        navigateYear(-1, availableYears: s.availableYears)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!canNavigateYear(-1, availableYears: s.availableYears))

                    Spacer()
                    Text(String(selectedYear))
                        .font(.headline)
                        .monospacedDigit()
                    Spacer()

                    Button {
                        navigateYear(1, availableYears: s.availableYears)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!canNavigateYear(1, availableYears: s.availableYears))
                }
                .padding(.vertical, 4)
            }

            let data: [(label: String, count: Int)] = {
                switch frequencyMode {
                case .yearly:  return s.entriesPerYear
                case .monthly: return s.monthData(for: selectedYear)
                case .weekly:  return s.weekData(for: selectedYear)
                case .daily:   return s.dayData(for: selectedYear)
                }
            }()

            if data.isEmpty {
                Text("No data")
                    .foregroundStyle(.secondary)
            } else {
                Chart {
                    ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                        BarMark(
                            x: .value("Period", item.label),
                            y: .value("Count", item.count)
                        )
                        .foregroundStyle(.tint)
                    }
                }
                .chartXAxis {
                    let desired: Int = {
                        switch frequencyMode {
                        case .yearly:  return max(data.count, 1)
                        case .monthly: return 12
                        case .weekly:  return 13  // show ~every 4th week label
                        case .daily:   return 7
                        }
                    }()
                    AxisMarks(values: .automatic(desiredCount: desired)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(axisLabel(for: label))
                            }
                        }
                    }
                }
                .frame(height: 220)
                .contentShape(Rectangle())
                .gesture(
                    frequencyMode.supportsYearNavigation
                    ? DragGesture(minimumDistance: 30, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.width < -30 {
                                withAnimation { navigateYear(1, availableYears: s.availableYears) }
                            } else if value.translation.width > 30 {
                                withAnimation { navigateYear(-1, availableYears: s.availableYears) }
                            }
                        }
                    : nil
                )
            }
        } header: {
            Label("Frequency", systemImage: "chart.bar")
        }
    }

    // MARK: - Year navigation helpers

    private func canNavigateYear(_ direction: Int, availableYears: [Int]) -> Bool {
        guard let idx = availableYears.firstIndex(of: selectedYear) else { return false }
        let newIdx = idx + direction
        return availableYears.indices.contains(newIdx)
    }

    private func navigateYear(_ direction: Int, availableYears: [Int]) {
        guard let idx = availableYears.firstIndex(of: selectedYear) else { return }
        let newIdx = idx + direction
        if availableYears.indices.contains(newIdx) {
            withAnimation { selectedYear = availableYears[newIdx] }
        }
    }

    /// Returns the axis display label based on the current frequency mode.
    private func axisLabel(for rawLabel: String) -> String {
        switch frequencyMode {
        case .yearly:
            return rawLabel
        case .monthly:
            return String(rawLabel.prefix(1))
        case .weekly:
            return rawLabel  // "W1", "W2", etc.
        case .daily:
            return Self.dayShortLabels[rawLabel] ?? rawLabel
        }
    }

    // MARK: - Reusable row helpers

    private func statRow(_ title: String, icon: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    // MARK: - Formatting helpers

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60

        if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        } else if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }

    /// Maps a 0-9 rating bucket to a colour matching the app's existing
    /// red → yellow → green gradient.
    private func barColor(for bucket: Int) -> Color {
        let rating = Double(bucket) / 9.0 * 10.0
        let hue = LogTheme.ratingHue(for: rating)
        return Color(hue: hue, saturation: 0.75, brightness: 0.90)
    }
}

#Preview {
    LogStatsView(entries: [])
}
