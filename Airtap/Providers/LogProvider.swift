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
}

struct LogEntry {
    var level: LogLevel
    var text: String
}

protocol LogProviding {
    func addLogEntry(entry: LogEntry)
}

class LogProvider: LogProviding {
    private var log: [LogEntry] = []
    
    init() {
    }
    
    func addLogEntry(entry: LogEntry) {
        log.append(entry)
        print(log)
    }
}
