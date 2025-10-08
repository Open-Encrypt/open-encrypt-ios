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
            SendMessageView()
                .tabItem {
                    Label("Send Message", systemImage: "paperplane.fill")
                }
            InboxMessagesView()
                .tabItem {
                    Label("Inbox", systemImage: "envelope.fill")
                }
            
            KeysView()
                .tabItem {
                    Label("Keys", systemImage: "key.fill")
                }
        }.navigationBarBackButtonHidden(true)
    }
}

struct SendMessageView: View {
    @State private var recipient: String = ""
    @State private var message: String = ""
    @State private var sendMessageStatus: Bool = false
    @State private var sendMessageErrorMessage: String? = ""
    
    var body: some View {
        VStack {
            Text("Send Message")
                .font(.headline)
                .padding()
            
            TextField("To:", text: $recipient)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            
            TextEditor(text: $message)
                .padding(8)
                .background(Color.white)
                .border(Color.gray.opacity(0.5), width: 1)
                .cornerRadius(8)
                .frame(width: 300, height: 150)
                .autocapitalization(.none)
            
            Button("Send") {
                let params = [
                    "recipient": recipient,
                    "message": message,
                    "action": "send_message"
                ]
                
                sendPOSTrequest(params: params) { returnValues in
                    DispatchQueue.main.async {
                        let status = returnValues["status"] as? Bool ?? false
                        let error = returnValues["error"] as? String
                        
                        sendMessageStatus = status
                        sendMessageErrorMessage = error
                        
                        if status {
                            // Clear both fields on success
                            recipient = ""
                            message = ""
                            
                            // Clear success message after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                sendMessageStatus = false
                            }
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            // Success message
            if sendMessageStatus {
                Text("Message sent successfully.")
                    .foregroundColor(.black)
                    .padding(.top, 4)
            }
            
            // Error message
            if let error = sendMessageErrorMessage,
               !error.isEmpty,
               error.lowercased() != "no error" {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding(.top, 4)
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
            Text("Public/Secret Keys")
                .font(.headline)
                .padding()
            
            Button("View Public Key") {
                let params = ["action": "get_public_key"]
                
                sendPOSTrequest(params: params) { returnValues in
                    DispatchQueue.main.async {
                        let ok = (returnValues["status"] as? Bool)
                              ?? ((returnValues["status"] as? String) == "success")
                        
                        getPublicKeyStatus = ok
                        getPublicKeyErrorMessage = returnValues["error"] as? String
                        publicKey = returnValues["public_key"] as? String ?? ""
                        secretKey = ""
                        
                        print("getPublicKeyErrorMessage:",getPublicKeyErrorMessage ?? "nil")
                        print("publicKey.count:", publicKey.count)
                    }
                }
            }
            
            Button("View Secret Key"){
                let username = UserDefaults.standard.string(forKey: "username")
                if let retrievedKey = retrieveSecretKey(username: username!) {
                    secretKey = retrievedKey
                    publicKey = ""
                    print("Retrieved secret key prefix: \(secretKey.prefix(30))")
                    print("publicKey.count:", secretKey.count)
                } else {
                    print("Failed to retrieve secret key")
                }

            }
            
            Button("Generate Keys"){
                let params = ["action": "generate_keys"]
                
                sendPOSTrequest(params: params) { returnValues in

                    DispatchQueue.main.async {
                        let ok = (returnValues["status"] as? Bool)
                              ?? ((returnValues["status"] as? String) == "success")
                        
                        getPublicKeyStatus = ok
                        getPublicKeyErrorMessage = returnValues["error"] as? String
                        
                        publicKey = returnValues["public_key"] as? String ?? ""
                        secretKey = returnValues["secret_key"] as? String ?? ""
                    }
                }
            }
            
            Button("Save Public Key (remote)"){
                if !publicKey.isEmpty{
                    let params = ["public_key": publicKey, "action": "save_public_key"]
                    sendPOSTrequest(params: params){ returnValues in
                        // Update the state on the main thread
                        DispatchQueue.main.async {
                            getPublicKeyStatus = returnValues["status"] as! Bool
                            getPublicKeyErrorMessage = returnValues["error"] as? String
                        }
                    }
                }
                else {
                    print("No public key to save. Public key must be generated.")
                }
            }
            
            Button("Save Secret Key (local)") {
                if let username = UserDefaults.standard.string(forKey: "username") {
                    let storeStatus = storeSecretKey(secretKey: secretKey, username: username)

                    if storeStatus == errSecSuccess {
                        print("Secret key stored successfully!")
                    } else {
                        print("Failed to store secret key with error code: \(storeStatus)")
                    }
                } else {
                    print("Username not found")
                }
            }
            
            // Scrollable view for secret key
            if !secretKey.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Secret Key:")
                        .font(.subheadline)
                    
                    ScrollView {
                        Text(secretKey)
                            .textSelection(.enabled) // allows copy
                            .padding(6)
                            .frame(alignment: .leading) // natural width, aligned left
                    }
                    .frame(height: 100) // adjust height as needed
                    .border(Color.gray.opacity(0.5), width: 1)
                    .padding(.horizontal) // space from screen edges
                }
                .padding(.bottom)
            }

            // Scrollable view for public key
            if !publicKey.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Public Key:")
                        .font(.subheadline)
                    ScrollView {
                        Text(publicKey)
                            .textSelection(.enabled)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100) // adjust height
                    .border(Color.gray.opacity(0.5), width: 1)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            } else if let error = getPublicKeyErrorMessage, !error.isEmpty, error != "No error" {
                Text("Display Public Key Error: \(error)")
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.bottom)
            }

        }
    }
}

    
    
struct InboxMessagesView: View {
    @State private var logout: Bool = false
    @State private var secretKey: String = ""
    @State private var getMessagesStatus: Bool = false
    @State private var getMessagesErrorMessage: String? = ""
    @State private var messageList: [(from: String, to: String, message: String, timestamp: String)] = []

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
                
                Button("Get Messages") {
                    // Clear previous messages before loading new ones
                    messageList.removeAll()
                    
                    let username = UserDefaults.standard.string(forKey: "username")
                    if let retrievedKey = retrieveSecretKey(username: username!) {
                        secretKey = retrievedKey
                        print("Retrieved secret key prefix: \(secretKey.prefix(30))")
                    } else {
                        print("Failed to retrieve secret key")
                    }
                    
                    let params = ["secret_key": secretKey, "action": "get_messages"]
                    
                    sendPOSTrequest(params: params) { returnValues in
                        DispatchQueue.main.async {
                            getMessagesStatus = returnValues["status"] as! Bool
                            getMessagesErrorMessage = returnValues["error"] as? String
                            
                            // Retrieve from, to, messages from response
                            let from = returnValues["from"] as! [String]
                            let to = returnValues["to"] as! [String]
                            let messages = returnValues["messages"] as! [String]
                            let timestamps = returnValues["timestamps"] as! [String]
                            
                            // Zip and reverse the message list so newest appear first
                            let combined = zip(zip(zip(from, to), messages), timestamps)
                                .map { ($0.0.0.0, $0.0.0.1, $0.0.1, $0.1) }
                            messageList = combined.reversed()
                        }
                    }
                }
                // place messages in a List view with (from,to,message) data arranged
                processMessages(messages: messageList)
                
            }
    }
}

import Security

func storeSecretKey(secretKey: String, username: String) -> OSStatus {
    let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: username,  // Associate the key with the username
        kSecAttrService as String: "com.open-encrypt-ios.app.secretkey",  // Unique service identifier
        kSecValueData as String: secretKey.data(using: .utf8)!  // Convert secret key to data
    ]
    
    // Delete any existing key for this username before saving the new one
    SecItemDelete(keychainQuery as CFDictionary)
    
    // Add the new secret key to the keychain
    let status = SecItemAdd(keychainQuery as CFDictionary, nil)
    return status
}

func retrieveSecretKey(username: String) -> String? {
    let keychainQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: username, // Use username to fetch the correct key
        kSecAttrService as String: "com.open-encrypt-ios.app.secretkey",
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)
    
    if status == errSecSuccess, let data = item as? Data {
        return String(data: data, encoding: .utf8)
    }
    
    return nil
}


// Define the function with named tuple elements
func processMessages(messages: [(from: String, to: String, message: String, timestamp: String)]) -> some View {
    // Formatter for parsing the server timestamp (assumed UTC)
    let parseFormatter = DateFormatter()
    parseFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    parseFormatter.timeZone = TimeZone(abbreviation: "UTC")

    // Formatter for displaying in New York time
    let displayFormatter = DateFormatter()
    displayFormatter.dateStyle = .short
    displayFormatter.timeStyle = .short
    displayFormatter.timeZone = TimeZone(identifier: "America/New_York") // set to EST

    return List(messages, id: \.message) { messageData in
        VStack(alignment: .leading) {
            Text("From: \(messageData.from)")
                .font(.headline)
            Text("To: \(messageData.to)")
                .font(.subheadline)
            
            if let date = parseFormatter.date(from: messageData.timestamp) {
                Text("Sent: \(displayFormatter.string(from: date))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(messageData.message)
                .font(.body)
        }
        .padding()
    }
}



// Define the function with a completion handler
func sendPOSTrequest(params: [String: String], completion: @escaping ([String: Any]) -> Void) {
    
    //determine action
    let action = params["action"]

    //fetch parameters
    let publicKey = params["public_key"]
    let secretKey = params["secret_key"]
    let message = params["message"]
    let recipient = params["recipient"]
    
    //initialize return values and API endpoint
    let endpoint = "inbox_ios.php"
    var returnValues : [String : Any] = ["status": false, "error": ""]
    
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
        returnValues["error"] = "Invalid or no token."
        completion(returnValues)
        return
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
    var json: [String: Any] = ["username": username!, "token": token!, "action": action!]
    switch action{
        case "get_messages":
            json["secret_key"] = secretKey!
        case "save_public_key":
            json["public_key"] = publicKey!
        case "send_message":
            json["message"] = message!
            json["recipient"] = recipient!
        case "generate_keys":
            break // nothing to send
        case "get_public_key":
            break // nothing to send
        default:
            print("sendPOSTrequest: Unrecognized action '\(action ?? "nil")' — no matching case in switch statement.")

    }
    let jsonData = try? JSONSerialization.data(withJSONObject: json)

    // Set HTTP body
    request.httpBody = jsonData
    
    // Create a URLSession data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error during task: \(error.localizedDescription)")
            returnValues["error"] = error.localizedDescription
            completion(returnValues)
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print("Error: Invalid response or no data.")
            returnValues["error"] = "Invalid response or no data."
            completion(returnValues)
            return
        }
        
        let decoder = JSONDecoder()
        
        //decode the response based on the reponse type
        switch action {
        case "get_messages":
                do {
                    // Define the shape and type of the JSON response
                    struct GetMessagesResponse: Codable {
                        let status: String
                        let error: String?
                        let from: [String]
                        let to: [String]
                        let messages: [String]
                        let timestamps: [String]
                    }
                    
                    // Decode as MessagesResponse
                    let decodedResponse = try decoder.decode(GetMessagesResponse.self, from: data)
                    
                    //set return values based on JSON response
                    returnValues["status"] = decodedResponse.status == "success"
                    returnValues["error"] = decodedResponse.error ?? "No error"
                    returnValues["from"] = decodedResponse.from
                    returnValues["to"] = decodedResponse.to
                    returnValues["messages"] = decodedResponse.messages
                    returnValues["timestamps"] = decodedResponse.timestamps
                    
                    //return the values
                    completion(returnValues)
                } catch {
                    print("Failed to decode MessagesResponse: \(error)")
                    returnValues["error"] = "Error decoding JSON."
                    completion(returnValues)
                }
        case "get_public_key":
            do {
                // Define the shape and type of the JSON response
                struct GetPublicKeyResponse: Codable {
                    let status: String
                    let error: String?
                    let public_key: String
                }
                
                // Decode as MessagesResponse
                let decodedResponse = try decoder.decode(GetPublicKeyResponse.self, from: data)
                print("Get public key response...")
                print("Status: \(decodedResponse.status)")
                print("Get Public Key Error: ", decodedResponse.error ?? "No error")
                print("Public Key Prefix: \(decodedResponse.public_key.prefix(30))")
                
                //set return values based on JSON response
                returnValues["status"] = decodedResponse.status == "success"
                returnValues["error"] = decodedResponse.error ?? "No error"
                returnValues["public_key"] = decodedResponse.public_key
                
                //return the values
                completion(returnValues)
            } catch {
                print("Failed to decode PublicKeyResponse: \(error)")
                returnValues["error"] = "Error decoding JSON."
                completion(returnValues)
            }
        case "generate_keys":
            do {
                // Define the shape and type of the JSON response
                struct GenerateKeysResponse: Codable {
                    let status: String
                    let error: String?
                    let public_key: String
                    let secret_key: String
                }
                
                // Decode as MessagesResponse
                let decodedResponse = try decoder.decode(GenerateKeysResponse.self, from: data)
                print("Generate keys response...")
                print("Status: \(decodedResponse.status)")
                print("Key Generation Error: ", decodedResponse.error ?? "No error")
                print("Public Key prefix: \(decodedResponse.public_key.prefix(30))...")
                print("Secret Key prefix: \(decodedResponse.secret_key.prefix(30))...")
                
                //set return values based on JSON response
                returnValues["status"] = decodedResponse.status == "success"
                returnValues["error"] = decodedResponse.error ?? "No error"
                returnValues["public_key"] = decodedResponse.public_key
                returnValues["secret_key"] = decodedResponse.secret_key
                
                //return the values
                completion(returnValues)
            } catch {
                print("Failed to decode PublicKeyResponse: \(error)")

                returnValues["error"] = "Error decoding JSON response during sendPOSTrequest for generate_keys."
                completion(returnValues)
            }
        case "save_public_key":
            do {
                // Define the shape and type of the JSON response
                struct SavePublicKeyResponse: Codable {
                    let status: String
                    let error: String?
                }
                
                // Decode as MessagesResponse
                let decodedResponse = try decoder.decode(SavePublicKeyResponse.self, from: data)
                print("Save public key response:")
                print("Status: \(decodedResponse.status)")
                print("Save Public Key Error: ", decodedResponse.error ?? "No error")
                
                //set return values based on JSON response
                returnValues["status"] = decodedResponse.status == "success"
                returnValues["error"] = decodedResponse.error ?? "No error"
                
                //return the values
                completion(returnValues)
            } catch {
                print("Failed to decode PublicKeyResponse: \(error)")
                returnValues["error"] = "Error decoding JSON."
                completion(returnValues)
            }
        case "send_message":
            do {
                // Define the shape and type of the JSON response
                struct SendMessageResponse: Codable {
                    let status: String
                    let error: String?
                }
                
                // Decode as MessagesResponse
                let decodedResponse = try decoder.decode(SendMessageResponse.self, from: data)
                print("Send message response:")
                print("Status: \(decodedResponse.status)")
                print("Send Message Error: ", decodedResponse.error ?? "No error")
                
                //set return values based on JSON response
                returnValues["status"] = decodedResponse.status == "success"
                returnValues["error"] = decodedResponse.error ?? "No error"
                
                //return the values
                completion(returnValues)
            } catch {
                print("Failed to decode PublicKeyResponse: \(error)")
                returnValues["error"] = "Error decoding JSON."
                completion(returnValues)
            }
        default:
            print("Unknown action: \(String(describing: action))")
        }
    }

    // Start the task
    task.resume()
}

#Preview {
    InboxView()
}
