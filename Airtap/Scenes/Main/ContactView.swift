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
    private let muteAction: () -> Void
    
    init(viewModel: ContactViewModel, muteAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.muteAction = muteAction
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
            
            Button {
                muteAction()
            } label: {
                Image(viewModel.isMuted ? "micOff" : "micOn")
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(viewModel.isMuted ? Theme.Colors.micOff : Theme.Colors.micOn)
                    .frame(height: 12)
            }
            .buttonStyle(LinkButtonStyle())
            
            
        }
    }
}

private extension Color {
    static let online = Color(red: 0.44, green: 0.76, blue: 0.00)
}
