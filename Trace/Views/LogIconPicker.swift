    //
//  LogIconPicker.swift
//  Trace
//
//  Created by Kayden Wang on 8/17/26.
//

import SwiftUI

// MARK: - Shared constants

enum LogTheme {
    /// Curated set of SF Symbols suitable for log categories.
    static let icons: [String] = [
        "book.closed", "book", "doc.text", "list.bullet", "note.text",
        "star", "heart", "bolt", "flame", "leaf",
        "cup.and.saucer", "fork.knife", "figure.walk", "bicycle", "car",
        "airplane", "house", "building.2", "music.note", "film",
        "gamecontroller", "paintbrush", "camera", "gift", "cart",
        "graduationcap", "briefcase", "stethoscope", "wrench", "globe",
        "flag", "mappin", "bell", "tag", "bookmark",
        "pencil", "lightbulb", "sun.max", "moon", "cloud"
    ]
    
    /// Palette of named colours matching Apple's system palette.
    static let colors: [(name: String, color: Color)] = [
        ("mint", .accentColor),
        ("peach", Color("TracePeach")),
        ("lavender", Color("TraceLavender")),
        ("blue", .blue),
        ("red", .red),
        ("green", .green),
        ("orange", .orange),
        ("purple", .purple),
        ("pink", .pink),
        ("yellow", .yellow),
        ("teal", .teal),
        ("indigo", .indigo),
        ("brown", .brown),
        ("cyan", .cyan)
    ]
    
    /// Resolves a stored colour name to a SwiftUI `Color`.
    static func color(for name: String) -> Color {
        colors.first(where: { $0.name == name })?.color ?? .accentColor
    }
    
    /// Maps a 0–10 rating to a hue on the red → yellow → green spectrum.
    static func ratingHue(for rating: Double) -> Double {
        let t = max(0, min(10, rating)) / 10.0
        if t <= 0.5 {
            return 0.0 + (0.16 - 0.0) * (t / 0.5)
        } else {
            return 0.16 + (0.33 - 0.16) * ((t - 0.5) / 0.5)
        }
    }
}

// MARK: - Icon Picker Section

/// Reusable form sections for choosing a log icon and colour.
/// Embeddable in both NewLogView and the LogView rename sheet.
struct LogIconPickerSections: View {
    @Binding var selectedIcon: String
    @Binding var selectedColor: String

    private let iconColumns = Array(repeating: GridItem(.adaptive(minimum: 44), spacing: 8), count: 1)
    private let colorColumns = Array(repeating: GridItem(.adaptive(minimum: 36), spacing: 10), count: 1)

    var body: some View {
        Section {
            LazyVGrid(columns: colorColumns, spacing: 10) {
                ForEach(LogTheme.colors, id: \.name) { item in
                    Button { selectedColor = item.name } label: {
                        Circle()
                            .fill(item.color)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if selectedColor == item.name {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.name)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Color")
        }

        Section {
            LazyVGrid(columns: iconColumns, spacing: 8) {
                ForEach(LogTheme.icons, id: \.self) { icon in
                    Button { selectedIcon = icon } label: {
                        Image(systemName: icon)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedIcon == icon ? LogTheme.color(for: selectedColor).opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(selectedIcon == icon ? LogTheme.color(for: selectedColor) : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(icon)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Icon")
        }
    }
}
