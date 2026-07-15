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
    
    @Relationship(deleteRule: .cascade, inverse: \Entry.log)
    var entries: [Entry] = []
    
    init(title: String) {
        self.createdAt = .now
        self.title = title
    }
}
