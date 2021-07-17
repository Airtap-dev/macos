//
//  ContactAvatarView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import SwiftUI

enum ContactAvatarViewSize {
    case small
    case medium
}

struct ContactAvatarView: View {
    private let initials: String
    private let circleSize: CGFloat
    private let fontSize: CGFloat
    
    init(initials: String, size: ContactAvatarViewSize) {
        self.initials = initials
        
        switch size {
        case .small:
            self.circleSize = 32
            self.fontSize = 12
        case .medium:
            self.circleSize = 48
            self.fontSize = 18
        }
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
                .frame(width: circleSize, height: circleSize)
            
            Text(initials)
                .font(
                    .system(size: fontSize, weight: .regular, design: .rounded)
                )
                .foregroundColor(.white)
        }
    }
}

private extension Color {
    static let avatarGradientTop = Color(red: 0.73, green: 0.20, blue: 0.95)
    static let avatarGradientBottom = Color(red: 0.37, green: 0.20, blue: 0.71)
}
