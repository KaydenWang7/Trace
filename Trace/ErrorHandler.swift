//
//  ErrorHandler.swift
//  Trace
//
//  Created by Kayden Wang on 8/25/26.
//

import Foundation
import SwiftUI

@MainActor @Observable
final class ErrorHandler {
    var currentError: (any LocalizedError)?
    var showError = false
    
    func handle(_ error: Error) {
        currentError = error as? (any LocalizedError)
        showError = true
    }
}
