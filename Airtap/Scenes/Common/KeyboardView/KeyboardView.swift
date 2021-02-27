//
//  KeyboardView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI

struct KeyboardView: View {
    private var keys: [String]
    
    init(_ prefix: [String] = ["⇧", "⌥"], key: String) {
        self.keys = prefix
        self.keys.append(key)
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(keys, id: \.self) { key in
                KeyboardKeyView(key)
            }
        }
    }
}
