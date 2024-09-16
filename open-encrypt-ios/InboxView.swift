//
//  InboxView.swift
//  open-encrypt-ios
//
//  Created by Jackson Walters on 9/12/24.
//

import SwiftUI


struct InboxView: View {
    
    var body: some View {
        TabView {
            InboxMessagesView()
                .tabItem {
                    Label("Inbox", systemImage: "envelope.fill")
                }
            
            KeysView()
                .tabItem {
                    Label("Keys", systemImage: "key.fill")
                }
        }
    }
}
 


struct KeysView: View {
    @State private var getPublicKeyStatus: Bool = false
    @State private var getPublicKeyErrorMessage: String? = ""
    @State private var publicKey: String = ""
    @State private var secretKey: String = ""
    
    var body: some View {
        VStack {
            Text("Stored Public Keys")
                .font(.headline)
                .padding()
            
            Button("View Public Key"){
                getPublicKey(){ success, error, public_key in
                    // Update the state on the main thread
                    DispatchQueue.main.async {
                        getPublicKeyStatus = success
                        getPublicKeyErrorMessage = error
                        publicKey = public_key
                    }
                }
            }
            
            // TextField for username input
            TextField("Secret key:", text: $secretKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            
            Button("Save Secret Key"){
                let secretKey = secretKey.data(using: .utf8)!  // Example key as Data
                let account = "com.open-encrypt-ios.user.secretKey" // A unique identifier for the key

                let storeStatus = storeKey(keyData: secretKey, account: account)

                if storeStatus == errSecSuccess {
                    print("Secret key stored successfully!")
                } else {
                    print("Failed to store secret key with error code: \(storeStatus)")
                }

            }
            
            Button("View Secret Key"){
                let account = "com.open-encrypt-ios.user.secretKey" // A unique identifier for the key
                
                if let retrievedKey = retrieveKey(account: account) {
                    let keyString = String(data: retrievedKey, encoding: .utf8)
                    print("Retrieved secret key: \(keyString ?? "Invalid Key")")
                } else {
                    print("Failed to retrieve secret key")
                }

            }
            
            // Display the retrieved public key
            if !publicKey.isEmpty {
                Text("Public Key:")
                    .font(.subheadline)
                    .padding(.top)
                Text(publicKey)
                    .padding()
            } else if let error = getPublicKeyErrorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

    
    
struct InboxMessagesView: View {
    @State private var logout: Bool = false
    @State private var secretKey: String = ""
    @State private var getMessagesStatus: Bool = false
    @State private var getMessagesErrorMessage: String? = ""
    @State private var messageList: [(from: String,to: String,message: String)] = []
    @Environment(\.dismiss) private var dismiss
        
    var body: some View {
        VStack{
                Text("Inbox")
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
                    
                    let account = "com.open-encrypt-ios.user.secretKey"
                    if let retrievedKey = retrieveKey(account: account) {
                        let secretKey = String(data: retrievedKey, encoding: .utf8)
                        print("Retrieved secret key: \(secretKey ?? "Invalid Key")")
                    } else {
                        print("Failed to retrieve secret key")
                    }
                    
                    getMessages(secretKey: secretKey){ success, error, messages in
                        // Update the state on the main thread
                        DispatchQueue.main.async {
                            getMessagesStatus = success
                            getMessagesErrorMessage = error
                            messageList = messages
                        }
                    }
                }
                
                // TextField for username input
                TextField("Secret key:", text: $secretKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                
                processMessages(messages: messageList)
                
            }
    }
}

import Security

func storeKey(keyData: Data, account: String) -> OSStatus {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecValueData as String: keyData
    ]
    SecItemDelete(query as CFDictionary) // Delete any existing item
    return SecItemAdd(query as CFDictionary, nil)
}

func retrieveKey(account: String) -> Data? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    
    if status == errSecSuccess {
        return dataTypeRef as? Data
    }
    return nil
}


// Define the function with named tuple elements
func processMessages(messages: [(from: String, to: String, message: String)]) -> some View {
    List(messages, id: \.message) { messageData in
        VStack(alignment: .leading) {
            Text("From: \(messageData.from)")
                .font(.headline)
            Text("To: \(messageData.to)")
                .font(.subheadline)
            Text(messageData.message)
                .font(.body)
        }
        .padding()
    }
}


// Define the function with a completion handler
func getMessages(secretKey: String, completion: @escaping (Bool, String?, [(String,String,String)]) -> Void) {
    
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
    let json: [String: Any] = ["username": username!, "token": token!, "action": "get_messages", "secret_key": secretKey]
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
            print("From:",decodedResponse.from)
            print("To:",decodedResponse.to)
            print("Messages:",decodedResponse.messages[2])
            
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

// Define the function with a completion handler
func getPublicKey(completion: @escaping (Bool, String?, String) -> Void) {
    
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
        completion(false,"Invalid or no token.", "")
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
    let json: [String: Any] = ["username": username!, "token": token!, "action": "get_public_key"]
    let jsonData = try? JSONSerialization.data(withJSONObject: json)

    // Set HTTP body
    request.httpBody = jsonData
    
    // Create a URLSession data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(false, nil,"")
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print("Error: Invalid response or no data")
            completion(false, nil, "")
            return
        }
        
        // Define the shape and type of the JSON response
        struct MessagesResponse: Codable {
            let status: String
            let error: String?
            let public_key: String
        }
        
        let decoder = JSONDecoder()
        do {
            let decodedResponse = try decoder.decode(MessagesResponse.self, from: data)
            print("Status: ", decodedResponse.status)
            print("Error: ", decodedResponse.error ?? "No error")
            
            //print the first message
            print("Public Key:",decodedResponse.public_key)
            
            // Determine success
            let success = decodedResponse.status == "success"
            completion(success, decodedResponse.error, decodedResponse.public_key)
        } catch {
            print("Error decoding JSON:", error)
            completion(false, "Error decoding JSON","")
        }
    }

    // Start the task
    task.resume()
}

#Preview {
    InboxView()
}
