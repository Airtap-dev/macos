//
//  APIDTO.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation

struct CreateAccountResponse: Decodable {
    let accountId: Int
    let shareableLink: String
    let token: String
}

struct StartSessionResponse: Decodable {
    let accountId: Int
    let firstName: String
    let lastName: String?
    let turnCredentials: [TurnCredentialsDTO]
    let shareableLink: String
}

struct TurnCredentialsDTO: Decodable {
    let url: String
    let username: String
    let password: String
}

struct DiscoverResponse: Decodable {
    let accountId: Int
    let firstName: String
    let lastName: String?
}
