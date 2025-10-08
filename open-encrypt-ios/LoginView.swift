//
//  ContentView.swift
//  open-encrypt-ios
//
//  Created by Jackson Walters on 9/11/24.
//

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginSuccessful: Bool = checkToken()
    @State private var loginErrorMessage: String? = ""
    
    var body: some View {
        NavigationStack {
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
                    let params = ["username": username, "password": password, "action": "login"]
                    accountRequest(params: params) { success, error in
                        // Update the state on the main thread
                        DispatchQueue.main.async {
                            loginSuccessful = success
                            loginErrorMessage = error
                        }
                    }
                }
                
                Button("Create Account") {
                    // Call the async function with completion handler
                    let params = ["username": username, "password": password, "action": "create_account"]
                    accountRequest(params: params) { success, error in
                        // Update the state on the main thread
                        DispatchQueue.main.async {
                            loginSuccessful = success
                            loginErrorMessage = error
                        }
                    }
                }
                
                if let errorMessage = loginErrorMessage {
                    Text(errorMessage)
                }
            }
            .padding()
            // Navigate to the SuccessView based on the state
            .navigationDestination(isPresented: $loginSuccessful) {
                InboxView()
            }
            
        }
    }
}

func checkToken() -> Bool {
    if let token = UserDefaults.standard.string(forKey: "token") {
        // Optionally, send token to server to verify its validity
        print("Token found: \(token)")
        // For simplicity, assume token is valid if it exists
        return true
    } else {
        print("No token found.")
        return false
    }
}

// Define the function with a completion handler
func accountRequest(params: [String: String], completion: @escaping (Bool, String?) -> Void) {
    //define variables from parameters
    let username : String = params["username"]!
    let password : String = params["password"]!
    let action : String = params["action"]!
    
    var endpoint = ""
    if action == "login" {
        endpoint = "api/login_ios.php"
    }
    if action == "create_account" {
        endpoint = "api/create_account_ios.php"
    }
    
    // Define the URL of the endpoint
    guard let url = URL(string: "https://open-encrypt.com/\(endpoint)") else {
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
            completion(false, nil)
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print("Error: Invalid response or no data")
            completion(false, nil)
            return
        }
        
        // Define the shape and type of the JSON response
        struct LoginResponse: Codable {
            let status: String
            let token: String?
            let error: String?
        }
        
        let decoder = JSONDecoder()
        do {
            let decodedResponse = try decoder.decode(LoginResponse.self, from: data)
            print("Status: ", decodedResponse.status)
            print("Token: ", decodedResponse.token ?? "No token")
            print("Error: ", decodedResponse.error ?? "No error")
            
            // Save token if available
            if let token = decodedResponse.token {
                UserDefaults.standard.set(token, forKey: "token")
                UserDefaults.standard.set(username, forKey: "username")
            }
            
            // Determine success
            let success = decodedResponse.status == "success"
            completion(success, decodedResponse.error)
            return
        } catch {
            print("Error decoding JSON:", error)
            completion(false, "Error decoding JSON")
            return
        }
    }

    // Start the task
    task.resume()
}


#Preview {
    LoginView()
}
