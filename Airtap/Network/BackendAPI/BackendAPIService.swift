//
//  BackendAPIService.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Combine
import TinyHTTP


protocol BackendAPIServing {
    func setIdentity(accountId: Int, token: String)
    
    func createAccount(licenseKey: String, firstName: String, lastName: String?) -> Future<CreateAccountResponse, NetworkingError>
    func discover(code: String) -> Future<DiscoverResponse, NetworkingError>
}

class BackendAPIService: BackendAPIServing {
    
    private var basicAuth: String?
    
    func setIdentity(accountId: Int, token: String) {
        if let authString = "\(accountId):\(token)".data(using: .utf8)?.base64EncodedString() {
            basicAuth = "Basic \(authString)"
        }
    }
    
    func createAccount(licenseKey: String, firstName: String, lastName: String?) -> Future<CreateAccountResponse, NetworkingError> {
        struct CreateAccountBody: Encodable {
            let licenseKey: String
            let firstName: String
            let lastName: String?
        }
        
        let payload = CreateAccountBody(licenseKey: licenseKey, firstName: firstName, lastName: lastName)
        
        return Endpoint<CreateAccountResponse>(baseURL: Config.apiEndpoint)
            .post(
                "account/create",
                body: payload
            )
            .asFuture()
    }
    
    func discover(code: String) -> Future<DiscoverResponse, NetworkingError> {
        return Endpoint<DiscoverResponse>(baseURL: Config.apiEndpoint)
            .get(
                "account/discover",
                params: [
                    "code": code
                ],
                auth: basicAuth
            )
            .asFuture()
    }
}
