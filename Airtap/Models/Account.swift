//
//  Account.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 13.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

struct Account: Identifiable, Hashable {
    var id: Int
    var firstName: String
    var lastName: String?
    var shareableLink: String
    var isSpeaking: Bool = false
}
