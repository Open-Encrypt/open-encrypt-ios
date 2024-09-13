//
//  InboxView.swift
//  open-encrypt-ios
//
//  Created by Jackson Walters on 9/12/24.
//

import SwiftUI

struct InboxView: View {
    @State private var logout: Bool = false
    @State private var getMessagesStatus: Bool = false
    @State private var getMessagesErrorMessage: String? = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack{
                Text("You are now logged in!")
                    .font(.largeTitle)
                    .navigationBarBackButtonHidden(true)
                    .padding()
                
                Button("Logout") {
                    // Clear user token
                    UserDefaults.standard.removeObject(forKey: "userToken")
                    print("Logging out...")
                    logout = true
                    dismiss()
                    
                }
                
                Button("Get Messages"){
                    getMessages(){ success, error in
                        // Update the state on the main thread
                        DispatchQueue.main.async {
                            getMessagesStatus = success
                            getMessagesErrorMessage = error
                        }
                    }
                }
                
            }
        }
    }
}

// Define the function with a completion handler
func getMessages(completion: @escaping (Bool, String?) -> Void) {
    
    // Declare username as an optional
    var username: String?

    if checkToken() {
        // retrieve the username from UserDefaults
        username = UserDefaults.standard.string(forKey: "username")
        print("Username is: \(username!)")
    }
    else{
        print("Invalid or no token.")
        completion(false,"Invalid or no token.")
    }
    
    // Define the URL of the endpoint
    guard let url = URL(string: "https://open-encrypt.com/inbox_ios.php") else {
        fatalError("Invalid URL")
    }

    // Create the URLRequest object
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Set the content type for JSON
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Create JSON data
    let json: [String: Any] = ["username": username!]
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
            let error: String?
        }
        
        let decoder = JSONDecoder()
        do {
            let decodedResponse = try decoder.decode(LoginResponse.self, from: data)
            print("Status: ", decodedResponse.status)
            print("Error: ", decodedResponse.error ?? "No error")
            
            
            // Determine success
            let success = decodedResponse.status == "success"
            completion(success, decodedResponse.error)
        } catch {
            print("Error decoding JSON:", error)
            completion(false, "Error decoding JSON")
        }
    }

    // Start the task
    task.resume()
}

#Preview {
    InboxView()
}
