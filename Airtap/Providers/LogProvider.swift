//
//  logProvider.swift
//  Airtap
//
//  Created by Ilya Andreev on 7/17/21.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation

enum LogLevel: Equatable {
    case error
    case debug
    case info
    
    func toEmojiTitle() -> String {
        switch self {
        case .error:
            return "❌ ERROR: "
        case .debug:
            return "⚠️ DEBUG: "
        case .info:
            return "ℹ️ INFO: "
        }
    }
}

struct LogEntry {
    var level: LogLevel
    var text: String
}

protocol LogProviding {
    func add(_ level: LogLevel, _ text: String)
}

class LogProvider: LogProviding {
    private var log: [LogEntry] = []
    
    init() {}
    
    func add(_ level: LogLevel, _ text: String) {
        log.append(LogEntry(level: level, text: text))
        print("\(level.toEmojiTitle())\(text)")
    }
}
