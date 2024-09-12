//
//  ContentView.swift
//  open-encrypt-ios
//
//  Created by Jackson Walters on 9/11/24.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var button_clicked: Bool = false
    @State private var loginSuccessful: Bool = false
    
    var body: some View {
        VStack {
            
            Text("Welcome to Open Encrypt")
            
            // TextField for username input
            TextField("Enter username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            
            // SecureField for password input
            SecureField("Enter password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Sign In", action: {
                send_http_request(username: username,password: password)
                button_clicked = true
            })
            if button_clicked {
                Text("Sending login request ...")
            }
            
            // Navigation destination for successful login
            NavigationLink(value: "SuccessView") {
                EmptyView()
            }
            .navigationDestination(for: String.self) { value in
                if value == "SuccessView" {
                    SuccessView()
                }
            }
        }
        .padding()
    }
}

struct SuccessView: View {
    var body: some View {
        Text("Login Successful! Welcome to the new view.")
            .padding()
    }
}

//function send HTTP post request
func send_http_request(username: String, password: String){

    // Define the URL of the endpoint
    guard let url = URL(string: "https://open-encrypt.com/login_ios.php") else {
        fatalError("Invalid URL")
    }

    // Create the URLRequest object
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Set the content type for JSON
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Create JSON data
    let json: [String: Any] = ["username": username,"password": password]
    let jsonData = try? JSONSerialization.data(withJSONObject: json)

    // Set HTTP body
    request.httpBody = jsonData
    
    // Create a URLSession data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print("Error: Invalid response or no data")
            return
        }
        
        print(data)
        
        //define the shape and type of the JSON response
        struct LoginResponse: Codable {
            let status: String
            let error: String
        }
        
        let decoder = JSONDecoder()
        do {
            let response = try decoder.decode(LoginResponse.self, from: data)
            print("Status: ", response.status)
            print("Error: ", response.error)
        } catch {
            print("Error decoding JSON:", error)
        }
        
    }

    // Start the task
    task.resume()
}

#Preview {
    ContentView()
}
