//
//  KeyboardKeyView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import SwiftUI

struct KeyboardKeyView: View {
    private let symbol: String
    
    init(_ symbol: String) {
        self.symbol = symbol
    }
    
    var body: some View {
        HStack {
            Text(symbol)
                .font(.system(size: 8, weight: .medium, design: .default))
                .frame(minWidth: 12)
                .foregroundColor(Theme.Colors.keyboardKeyContent)
                .padding(2)
        }
        .background(Theme.Colors.keyboardKeyBackground)
        .cornerRadius(3)
        .shadow(color: Theme.Colors.keyboardKeyShadow, radius: 3, x: 0, y: 0)
    }
}
