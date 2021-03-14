//
//  Analytics.swift
//  Airtap (Production)
//
//  Created by Aleksandr Litreev on 14.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Amplitude

enum AnalyticsEvent: String {
    case appStart = "app_start"
    case copyLink = "copy_link"
    case addPeer = "add_peer"
    case deletePeer = "delete_peer"
    case mutePeer = "mute_peer"
    case unmutePeer = "unmute_peer"
}

class Analytics {
    static func start(accountId: Int) {
        #if !DEBUG
        Amplitude.instance()?.initializeApiKey(Config.amplitudeApiKey)
        Amplitude.instance()?.setUserId("\(accountId)")
        Analytics.track(.appStart)
        #endif
    }
    
    static func track(_ event: AnalyticsEvent) {
        #if !DEBUG
        Amplitude.instance().logEvent(event.rawValue)
        #endif
    }
}
