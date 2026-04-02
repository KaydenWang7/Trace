//
//  SettingsView.swift
//  Trace
//
//  Created by Kayden Wang on 3/25/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showGradient") private var showGradient: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: $showGradient) {
                        Text("Show gradient backgrounds")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
