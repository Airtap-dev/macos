//
//  Resolver.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

class Resolver {
    let apiService: APIServing
    let wsService: WSServing
    let webRTCService: WebRTCServing
    
    let authProvider: AuthProviding
    let persistenceProvider: PersistenceProviding
    let callProvider: CallProviding
    
    let linkHandler: LinkHandling

    init(authProvider: AuthProviding) {
        self.apiService = APIService(authProvider: authProvider)
        self.wsService = WSService(authProvider: authProvider)
        self.webRTCService = WebRTCService(authProvider: authProvider)
        
        self.authProvider = authProvider
        self.persistenceProvider = PersistenceProvider(authProvider: authProvider)
        self.callProvider = CallProvider(
            webRTCService: webRTCService,
            apiService: apiService,
            wsService: wsService,
            authProvider: authProvider,
            persistenceProvider: persistenceProvider
        )
        
        self.linkHandler = LinkHandler(
            authProvider: authProvider,
            apiService: apiService,
            persistenceProvider: persistenceProvider
        )
    }
    
    // MARK: - Routing -
    func welcome() -> WelcomeView {
        let m = WelcomeModel(apiService: apiService, authProvider: authProvider)
        let vm = WelcomeViewModel(model: m)
        let v = WelcomeView(viewModel: vm)
        
        return v
    }
    
    func main() -> MainView {
        let m = MainModel(authProvider: authProvider, callProvider: callProvider, persistenceProvider: persistenceProvider)
        let vm = MainViewModel(model: m)
        let v = MainView(viewModel: vm)
        
        return v
    }
}
