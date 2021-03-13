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
                WaveView(
                    strength: (viewModel.isAccountOwnerSpeaking || viewModel.currentPeer != nil) ? 9 : 3,
                    frequency: 16,
                    phase: self.phase + Double(8 * i) / 2
                )
                .stroke(
                    AngularGradient(
                        gradient: Gradient(
                            colors: (viewModel.isAccountOwnerSpeaking || viewModel.currentPeer != nil) ? [
                                i % 2 == 0 ?
                                    Theme.Colors.waveGradientStart :
                                    Theme.Colors.waveGradientEnd,
                                i % 2 == 0 ?
                                    Theme.Colors.waveGradientEnd :
                                    Theme.Colors.waveGradientStart,
                            ] : [
                                i % 2 == 0 ?
                                    Theme.Colors.waveGradientMutedStart :
                                    Theme.Colors.waveGradientMutedEnd,
                                i % 2 == 0 ?
                                    Theme.Colors.waveGradientMutedEnd :
                                    Theme.Colors.waveGradientMutedStart,
                            ]
                        ),
                        center: .center,
                        startAngle: .degrees(270),
                        endAngle: .degrees(0)
                    ),
                    lineWidth: 2
                )
                .frame(height: 32)
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                self.phase = .pi * 2
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            
            VStack(spacing: 0) {
                HStack {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 22)
                        .padding(.vertical, 12)
                        .padding(.leading, 12)
                    
                    Spacer()
                    
                    Button {
                        print("fdf")
                    } label: {
                        Image("link")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Theme.Colors.copyLinkButton)
                            .frame(height: 16)
                        
                    }
                    .buttonStyle(LinkButtonStyle())
                    .padding(.vertical, 12)
                    .padding(.trailing, 16)
                }
                
                Divider()
            }
            
            VStack(spacing: 16) {
                ZStack {
                    waves
                    
                    HStack {
                        ContactAvatarView(initials: viewModel.accountOwnerInitials, size: .medium)
                    }
                    .padding(.leading, (viewModel.isAccountOwnerSpeaking && viewModel.currentPeer != nil) ? 40 : 0)
                    .opacity(viewModel.isAccountOwnerSpeaking ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2))
                    
                    HStack {
                        ContactAvatarView(initials: viewModel.currentPeerInitials, size: .medium)
                    }
                    .padding(.trailing, (viewModel.isAccountOwnerSpeaking && viewModel.currentPeer != nil) ? 40 : 0)
                    .opacity(viewModel.currentPeer != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2))
                }
                HStack {
                    Group {
                        if (!viewModel.isAccountOwnerSpeaking && viewModel.currentPeer == nil) {
                            Text(Lang.noOneSpeaking)
                        } else {
                            if (viewModel.isAccountOwnerSpeaking && viewModel.currentPeer != nil) {
                                Text(String(format: Lang.youAndPeerSpeaking, viewModel.currentPeer?.firstName ?? ""))
                            } else {
                                if viewModel.isAccountOwnerSpeaking {
                                    Text(String(format: Lang.youSpeaking))
                                } else {
                                    Text(String(format: Lang.peerSpeaking, viewModel.currentPeer?.firstName ?? ""))
                                }
                            }
                        }
                    }
                    .foregroundColor(Theme.Colors.mainText)
                    .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.top, 16)
            
            VStack {
                ForEach(viewModel.contactViewModels.indices, id: \.self) { index in
                    ContactView(viewModel: viewModel.contactViewModels[index])
                        .background(Color.clear)
                        .contextMenu {
                            Button {
                                self.viewModel.removePeer(index)
                            } label: {
                                Text(Lang.removePeer)
                            }
                        }
                }
            }
            .padding()
            
            Spacer()
        }
        .frame(width: 250)
        .cornerRadius(8)
    }
}

extension Color {
    static let gradientColor1 = Color(red: 0.97, green: 0.00, blue: 0.30).opacity(0.5)
    static let gradientColor2 = Color(red: 1.00, green: 0.40, blue: 0.11).opacity(0.5)
}
