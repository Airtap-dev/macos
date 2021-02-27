//
//  KeyboardKeyView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
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
                .font(.system(size: 10, weight: .medium, design: .default))
                .frame(minWidth: 12)
                .foregroundColor(.keyContent)
                .padding(2)
        }
        .background(Color.keyBackground)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.keyBorder, lineWidth: 1)
        )
    }
}

private extension Color {
    static let keyContent = Color(red: 0.67, green: 0.67, blue: 0.67)
    static let keyBackground = Color(red: 0.93, green: 0.93, blue: 0.93)
    static let keyBorder = Color(red: 0.87, green: 0.87, blue: 0.87)
}
