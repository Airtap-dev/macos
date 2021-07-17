//
//  logProvider.swift
//  Airtap
//
//  Created by Ilya Andreev on 7/17/21.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation

enum logLevel: Equatable {
    case error
    case debug
    case info
}

struct LogEntry {
    var level: logLevel
    var text: String
}

protocol LogProviding {
    var log: [LogEntry] { get }
    
    func addLogEntry(entry: LogEntry)
}

class LogProvider: LogProviding {
    private(set) var log: [LogEntry] = []
    
    init() {
    }
    
    func addLogEntry(entry: LogEntry) {
        log.append(entry)
        print(log)
    }
}
