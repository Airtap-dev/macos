//
//  APIError.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation

enum APIError: Int {
    case internalError = 0
    case invalidBody = 1
    case invalidLicense = 2
    case invalidDiscoveryCode = 3
    case invalidCredentials = 4
}
