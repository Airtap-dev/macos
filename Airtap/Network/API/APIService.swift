//
//  APIService.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation
import Combine
import TinyHTTP

enum APIServiceEvent: Equatable {
    case identitySet
    case identityRemoved
}

protocol APIServing {
    var eventSubject: PassthroughSubject<APIServiceEvent, Never> { get }
    
    func createAccount(licenseKey: String, firstName: String, lastName: String?) -> Future<CreateAccountResponse, NetworkingError>
    func startSession() -> Future<StartSessionResponse, NetworkingError>
    func discover(code: String) -> Future<DiscoverResponse, NetworkingError>
}

class APIService: APIServing {
    private let authProvider: AuthProviding
    private let logProvider: LogProviding
    
    private(set) var eventSubject = PassthroughSubject<APIServiceEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private var basicAuth: String?
    
    init(authProvider: AuthProviding, logProvider: LogProviding) {
        self.authProvider = authProvider
        self.logProvider = logProvider
        
        self.authProvider.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case let .signedIn(accountId, token):
                    self?.setIdentity(accountId: accountId, token: token)
                case .signedOut:
                    self?.dropIdentity()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setIdentity(accountId: Int, token: String) {
        if let authString = "\(accountId):\(token)".data(using: .utf8)?.base64EncodedString() {
            basicAuth = "Basic \(authString)"
        }
        eventSubject.send(.identitySet)
    }
    
    private func dropIdentity() {
        basicAuth = nil
        eventSubject.send(.identityRemoved)
    }
    
    func createAccount(licenseKey: String, firstName: String, lastName: String?) -> Future<CreateAccountResponse, NetworkingError> {
        self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "creating a new account")))
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
    
    func startSession() -> Future<StartSessionResponse, NetworkingError> {
        self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "starting a new account session")))
        return Endpoint<StartSessionResponse>(baseURL: Config.apiEndpoint)
            .get(
                "account/start",
                auth: basicAuth
            )
            .asFuture()
    }
    
    func discover(code: String) -> Future<DiscoverResponse, NetworkingError> {
        self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "discovering a new peer with code %@", code)))
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
