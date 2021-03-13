//
//  ContactView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI

struct ContactView: View {
    private let viewModel: ContactViewModel
    
    init(viewModel: ContactViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ContactAvatarView(initials: viewModel.name.initials(limit: 2), size: .small)
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.name)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(Theme.Colors.mainText)
                    .lineLimit(1)
                
                KeyboardView(key: viewModel.key)
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
