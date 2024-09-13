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
    @State private var messageList: [(from: String,to: String,message: String)] = []
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
                    getMessages(){ success, error, messages in
                        // Update the state on the main thread
                        DispatchQueue.main.async {
                            getMessagesStatus = success
                            getMessagesErrorMessage = error
                            messageList = messages
                            print(messageList[0].from)
                        }
                    }
                }
                
                processMessages(messages: messageList)
                
            }
        }
    }
}

// Define the function with named tuple elements
func processMessages(messages: [(from: String, to: String, message: String)]) -> some View {
    List(messages, id: \.from) { message in
        VStack(alignment: .leading) {
            Text("From: \(message.from)")
                .font(.headline)
            Text("To: \(message.to)")
                .font(.subheadline)
            Text(message.message)
                .font(.body)
        }
        .padding()
    }
}


// Define the function with a completion handler
func getMessages(completion: @escaping (Bool, String?, [(String,String,String)]) -> Void) {
    
    // Declare username as an optional
    var username: String?
    var token: String?

    if checkToken() {
        // retrieve the username from UserDefaults
        username = UserDefaults.standard.string(forKey: "username")
        token = UserDefaults.standard.string(forKey: "token")
        print("Username from UserDefaults: \(username!)")
        print("Token from UserDefaults: \(token!)")
    }
    else{
        print("Invalid or no token.")
        completion(false,"Invalid or no token.", [])
        return
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
    let json: [String: Any] = ["username": username!, "token": token!]
    let jsonData = try? JSONSerialization.data(withJSONObject: json)

    // Set HTTP body
    request.httpBody = jsonData
    
    // Create a URLSession data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(false, nil, [])
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print("Error: Invalid response or no data")
            completion(false, nil, [])
            return
        }
        
        // Define the shape and type of the JSON response
        struct MessagesResponse: Codable {
            let status: String
            let error: String?
            let from: [String]
            let to: [String]
            let messages: [String]
        }
        
        let decoder = JSONDecoder()
        do {
            let decodedResponse = try decoder.decode(MessagesResponse.self, from: data)
            print("Status: ", decodedResponse.status)
            print("Error: ", decodedResponse.error ?? "No error")
            
            //print the first message
            print("From:",decodedResponse.from.prefix(1))
            print("To:",decodedResponse.to.prefix(1))
            print("Messages:",decodedResponse.messages.prefix(1))
            
            // zip three lists of from, to, message into a single list
            var messages: [(from: String, to: String, message: String)] = []
            let numMessages = decodedResponse.messages.count
            for i in 0...numMessages-1 {
                messages.append((from: decodedResponse.from[i], to: decodedResponse.to[i], message: decodedResponse.messages[i]))
            }
            
            // Determine success
            let success = decodedResponse.status == "success"
            completion(success, decodedResponse.error,messages)
        } catch {
            print("Error decoding JSON:", error)
            completion(false, "Error decoding JSON",[])
        }
    }

    // Start the task
    task.resume()
}

#Preview {
    InboxView()
}
