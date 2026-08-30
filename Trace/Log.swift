//
//  Log.swift
//  Trace
//
//  Created by Kayden Wang on 4/3/26.
//

import Foundation
import SwiftData

@Model
final class Log {
    var createdAt: Date
    var title: String
    var icon: String = "book.closed"
    var iconColor: String = "blue"
    
    @Relationship(deleteRule: .cascade, inverse: \Entry.log)
    var entries: [Entry] = []
    
    init(title: String, icon: String = "book.closed", iconColor: String = "blue") {
        self.createdAt = .now
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
    }
}
