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
            
            Button("Login") {
                // Call the async function with completion handler
                send_http_request(username: username, password: password) { success in
                    // Update the state on the main thread
                    DispatchQueue.main.async {
                        loginSuccessful = success
                    }
                }
            }

            if loginSuccessful {
                Text("Login was successful!")
            } else {
                Text("Please log in.")
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

// Define the function with a completion handler
func send_http_request(username: String, password: String, completion: @escaping (Bool) -> Void) {
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
    let json: [String: Any] = ["username": username, "password": password]
    let jsonData = try? JSONSerialization.data(withJSONObject: json)

    // Set HTTP body
    request.httpBody = jsonData
    
    // Create a URLSession data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print("Error: Invalid response or no data")
            completion(false)
            return
        }
        
        // Define the shape and type of the JSON response
        struct LoginResponse: Codable {
            let status: String
            let error: String?
        }
        
        let decoder = JSONDecoder()
        do {
            let decodedResponse = try decoder.decode(LoginResponse.self, from: data)
            print("Status: ", decodedResponse.status)
            print("Error: ", decodedResponse.error ?? "No error")
            if decodedResponse.status == "success" {
                completion(true)
            } else {
                completion(false)
            }
        } catch {
            print("Error decoding JSON:", error)
            completion(false)
        }
    }

    // Start the task
    task.resume()
}

#Preview {
    ContentView()
}
