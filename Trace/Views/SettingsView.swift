//
//  SettingsView.swift
//  Trace
//
//  Created by Kayden Wang on 3/25/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showGradient") private var showGradient: Bool = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: $showGradient) {
                        Text("Show rating gradients")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
