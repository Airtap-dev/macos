//
//  MainWireframe.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 13.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

class MainWireframe {
    private let resolver: Resolver
    
    init(_ resolver: Resolver) {
        self.resolver = resolver
    }
    
    func welcome() -> WelcomeView {
        resolver.welcome()
    }
}
