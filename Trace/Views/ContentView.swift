//
//  ContentView.swift
//  Trace
//
//  Created by Kayden Wang on 2/1/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("test") {
                    LogView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Entry.self, inMemory: true)
}
