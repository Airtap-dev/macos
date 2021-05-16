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
    static let env = "staging"
    static let apiEndpoint = "https://api-staging.airtap.dev/"
    static let wsEndpoint = "wss://api-staging.airtap.dev/ws"
    #else
    static let env = "production"
    static let apiEndpoint = "https://api.airtap.dev/"
    static let wsEndpoint = "wss://api.airtap.dev/ws"
    #endif
    
    static let sentryEndpoint = "https://a4b613b9830c4b66bad17e53678e7c11@o541219.ingest.sentry.io/5674895"
}
