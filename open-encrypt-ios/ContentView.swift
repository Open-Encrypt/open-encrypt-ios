//
//  ContentView.swift
//  open-encrypt-ios
//
//  Created by Jackson Walters on 9/11/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Welcome to Open Encrypt")
            Button(action: signIn) {
                Text("Sign In")
            }


        }
        .padding()
    }
    func signIn(){
        print("button clicked")
    }

}

#Preview {
    ContentView()
}
