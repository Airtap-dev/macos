//
//  Config.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

struct Config {
    #if STAGING
    static let apiEndpoint = "https://api-staging.airtap.dev/"
    static let wsEndpoint = "wss://api-staging.airtap.dev/ws"
    static let sparkleEndpoint = "https://update.airtap.dev/app-staging.xml"
    #else
    static let apiEndpoint = "https://api.airtap.dev/"
    static let wsEndpoint = "wss://api.airtap.dev/ws"
    static let sparkleEndpoint = "https://update.airtap.dev/app.xml"
    #endif
}
