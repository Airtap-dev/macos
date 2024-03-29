//
//  WelcomeView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    
    @ObservedObject private var viewModel: WelcomeViewModel
    
    init(viewModel: WelcomeViewModel, logProvider: LogProviding) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 50)
                .padding(.bottom, 16)
            
            Group {
                TextField(Lang.licenseKey, text: Binding<String>(get: { viewModel.licenseKey }, set: { viewModel.licenseKey = $0 }))
                TextField(Lang.firstName, text: Binding<String>(get: { viewModel.firstName }, set: { viewModel.firstName = $0 }))
                TextField(Lang.lastName, text: Binding<String>(get: { viewModel.lastName }, set: { viewModel.lastName = $0 }))
            }
            .textFieldStyle(WelcomeTextFieldStyle())
            .frame(width: 300)
            
            Button(action: {
                viewModel.signUp()
            }, label: {
                Text(Lang.signUp)
            })
            .padding(.top, 16)
        }
        .padding()
    }
}

struct WelcomeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(PlainTextFieldStyle())
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .padding(8)
            .background(Theme.Colors.textFieldBackground)
            .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
            .shadow(color: Color.black.opacity(0.2), radius: 1)
    }
}
