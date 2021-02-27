//
//  ContactView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI

struct ContactView: View {
    private let name: String
    private let key: String
    
    init(name: String, key: String) {
        self.name = name
        self.key = key
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ContactAvatarView(initials: name.initials(limit: 2))
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .lineLimit(1)
                    .font(.system(size: 14, weight: .medium, design: .default))
                
                KeyboardView(key: key)
            }
            
            Spacer()
            
            Circle()
                .fill(Color.online)
                .frame(width: 10, height: 10)
        }
    }
}

private extension Color {
    static let online = Color(red: 0.44, green: 0.76, blue: 0.00)
}
