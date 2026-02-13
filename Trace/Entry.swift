//
//  Entry.swift
//  Trace
//
//  Created by Kayden Wang on 2/1/26.
//

import Foundation
import SwiftData

@Model
final class Entry {
    var timestamp: Date
    var title: String
    
    init(timestamp: Date, title: String) {
        self.timestamp = timestamp
        self.title = title
    }
}
