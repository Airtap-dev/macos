//
//  ContactAvatarView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI

struct ContactAvatarView: View {
    private let initials: String
    
    init(initials: String) {
        self.initials = initials
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                .avatarGradientTop,
                                .avatarGradientBottom
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 44, height: 44)
            
            Text(initials)
                .font(
                    .system(size: 18, weight: .medium, design: .rounded)
                )
                .foregroundColor(.white)
        }
    }
}

private extension Color {
    static let avatarGradientTop = Color(red: 0.73, green: 0.20, blue: 0.95)
    static let avatarGradientBottom = Color(red: 0.37, green: 0.20, blue: 0.71)
}
