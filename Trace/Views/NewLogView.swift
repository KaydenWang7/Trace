//
//  NewLogView.swift
//  Trace
//
//  Created by Kayden Wang on 8/17/26.
//

import SwiftUI

struct NewLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var icon: String = "book.closed"
    @State private var iconColor: String = "mint"
    @FocusState private var isTitleFocused: Bool
    var onSave: (_ title: String, _ icon: String, _ iconColor: String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        // Live preview of the icon
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(LogTheme.color(for: iconColor), in: RoundedRectangle(cornerRadius: 8))
                        TextField("Log title", text: $title)
                            .textInputAutocapitalization(.words)
                            .focused($isTitleFocused)
                    }
                }

                LogIconPickerSections(selectedIcon: $icon, selectedColor: $iconColor)
            }
            .navigationTitle("New Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, icon, iconColor)
                        dismiss()
                    }
                }
            }
            .onAppear {
                isTitleFocused = true
            }
        }
    }
}
