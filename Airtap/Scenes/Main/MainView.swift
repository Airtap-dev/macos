//
//  ContentView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI

struct MainView: View {
    
    @State private var phase = 0.0
    
    @ObservedObject private var viewModel: MainViewModel
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    var waves: some View {
        ZStack {
            ForEach(0..<2) { i in
                Wave(strength: 8, frequency: 16, phase: self.phase + Double(8 * i) / 2)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(
                                colors: [
                                    i % 2 == 0 ? .gradientColor1 : .gradientColor2,
                                    i % 2 == 0 ? .gradientColor2 : .gradientColor1,
                                ]
                            ),
                            center: .center,
                            startAngle: .degrees(270),
                            endAngle: .degrees(0)
                        ),
                        lineWidth: 2
                    )
                    .frame(height: 44)
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                self.phase = .pi * 2
            }
        }
    }
    
    var body: some View {
        
        ZStack {
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow
            )
            VStack(spacing: 8) {
                VStack(spacing: 16) {
                    ZStack {
                        waves
                        HStack {
                            ContactAvatarView(initials: "AL")
                        }
                    }
                    HStack {
                        Text("Alex is speaking...")
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                .padding(.top, 16)
                VStack {
                    ForEach(viewModel.contactViewModels, id: \.self) { vm in
                        ContactView(viewModel: vm)
                    }
                }
                .padding()
                
                Spacer()
            }
            .background(Color.white.opacity(0.5))
        }
        .frame(width: 250)
        .cornerRadius(8)
        .padding()
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
        
    }
}

extension Color {
    static let gradientColor1 = Color(red: 0.97, green: 0.00, blue: 0.30).opacity(0.5)
    static let gradientColor2 = Color(red: 1.00, green: 0.40, blue: 0.11).opacity(0.5)
}
