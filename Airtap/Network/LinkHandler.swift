//
//  LinkHandler.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 01.03.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation
import Combine

protocol LinkHandling {
    func handleURL(url: URL)
}

class LinkHandler: LinkHandling {
    private let authProvider: AuthProviding
    private let apiService: APIServing
    private let persistenceProvider: PersistenceProviding
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authProvider: AuthProviding, apiService: APIServing, persistenceProvider: PersistenceProviding) {
        self.apiService = apiService
        self.persistenceProvider = persistenceProvider
        self.authProvider = authProvider
    }
    
    func handleURL(url: URL) {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if urlComponents.host == "discover" {
                handleDiscoverURL(queryItems: urlComponents.queryItems)
            }
        }
    }
    
    private func handleDiscoverURL(queryItems: [URLQueryItem]?) {
        guard let code = queryItems?.first(where: { item -> Bool in item.name == "code" })?.value else { return }
            
        apiService.discover(code: code)
            .sink(receiveCompletion: { _ in
                // no-op
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                if let selfAccountId = self.authProvider.accountId, response.accountId != selfAccountId {
                    if self.persistenceProvider.peers.count < 6 {
                        self.persistenceProvider.insertPeer(
                            id: response.accountId,
                            firstName: response.firstName,
                            lastName: response.lastName
                        )
                    }
                }
            }).store(in: &cancellables)
    }
}
