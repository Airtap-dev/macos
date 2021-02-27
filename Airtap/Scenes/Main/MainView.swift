//
//  ContentView.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        VStack {
            ContactView(name: "Ilia Andreev", key: "1")
            ContactView(name: "Aleksandr Litreev", key: "2")
            ContactView(name: "Queen Elisabeth", key: "3")
        }.frame(width: 200)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
