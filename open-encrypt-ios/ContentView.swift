//
//  ContentView.swift
//  open-encrypt-ios
//
//  Created by Jackson Walters on 9/11/24.
//

import SwiftUI

struct ContentView: View {
    @State var button_clicked: Bool = false
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Welcome to Open Encrypt")
            Button("Sign In", action: {
                button_clicked = !button_clicked
            })
            if button_clicked {
                Text("Button clicked!")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
