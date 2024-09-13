//
//  InboxView.swift
//  open-encrypt-ios
//
//  Created by Jackson Walters on 9/12/24.
//

import SwiftUI

struct InboxView: View {
    @State private var logout: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack{
                Text("You are now logged in!")
                    .font(.largeTitle)
                    .navigationBarBackButtonHidden(true)
                
                Button("Logout") {
                    // Clear user token
                    UserDefaults.standard.removeObject(forKey: "userToken")
                    print("Logging out...")
                    logout = true
                    dismiss()
                    
                }
                .padding()
            }
        }

    }
    
}

#Preview {
    InboxView()
}
