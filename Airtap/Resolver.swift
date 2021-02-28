//
//  Resolver.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

class Resolver {
    
    private let backendService  = BackendAPIService()
    private let webRTCService = WebRTCService()
    private let authProvider = AuthProvider()

    func welcome() -> WelcomeView {
        let m = WelcomeModel(backendService: backendService, authProvider: authProvider)
        let vm = WelcomeViewModel(model: m)
        let v = WelcomeView(viewModel: vm)
        
        return v
    }
    
    func main() -> MainView {
        let m = MainModel()
        let vm = MainViewModel(model: m)
        let v = MainView(viewModel: vm)
        
        return v
    }
    
}
