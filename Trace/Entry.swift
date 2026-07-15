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
    var rating: Double?
    var desc: String? = nil
    
    var log: Log?
    
    init(timestamp: Date, title: String, rating: Double? = nil, desc: String? = nil, log: Log? = nil) {
        self.timestamp = timestamp
        self.title = title
        self.rating = rating
        self.desc = desc
        self.log = log
    }
}

