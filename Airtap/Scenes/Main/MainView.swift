//
//  ContentView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @State private var phase = 0.0
    
    @ObservedObject private var viewModel: MainViewModel
    private let wireframe: MainWireframe!
    
    init(viewModel: MainViewModel, wireframe: MainWireframe) {
        self.viewModel = viewModel
        self.wireframe = wireframe
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
    
    var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Image("logo")
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 22)
                    .padding(.vertical, 12)
                    .padding(.leading, 12)
                
                Spacer()
                
                Button {
                    viewModel.copyShareableLink()
                } label: {
                    Image("link")
                        .resizable()
                        .antialiased(true)
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
    }
    
    var heading: some View {
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
    }
    
    var peerList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.contactViewModels.indices, id: \.self) { index in
                ContactView(viewModel: viewModel.contactViewModels[index], muteAction: {
                    self.viewModel.toggleMutePeer(index)
                })
                .background(Color.clear)
                .contextMenu {
                    Button {
                        self.viewModel.toggleMutePeer(index)
                    } label: {
                        Text(viewModel.contactViewModels[index].isMuted ? Lang.unmutePeer : Lang.mutePeer)
                    }
                    Button {
                        self.viewModel.removePeer(index)
                    } label: {
                        Text(Lang.removePeer)
                    }
                }
            }
        }
        .padding()
    }
    
    var onboarding: some View {
        VStack(spacing: 0) {
            HStack {
                Image("logo")
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 22)
                    .padding(.vertical, 12)
            }
            
            Divider()
            
            VStack {
                Text("Please, activate your app to get started.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, weight: .medium))
                
                Button {
                    (NSApplication.shared.delegate as! AppDelegate).openWelcomeWindow()
                } label: {
                    Text("Let's do it")
                }
            }
            .padding()
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if viewModel.shouldShowOnboarding {
                onboarding
            } else {
                topBar
                heading
                peerList
            }
        }
        .frame(width: 200)
        
        
    }
}
