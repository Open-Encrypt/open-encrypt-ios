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
            
            // TextField for username input
            TextField("To:", text: $recipient)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            
            // TextField for username input
            TextEditor(text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
                .background(Color.white) // Background color
                .border(Color.gray, width: 1) // Simple border
                .frame(width: 300, height: 150) // Fixed width and height
            //button to send message

            Button("Send") {
                let params = ["recipient": recipient, "message": message, "action": "send_message"]
                sendMessage(params: params){ success, error in
                    // Update the state on the main thread
                    DispatchQueue.main.async {
                        sendMessageStatus = success
                        sendMessageErrorMessage = error
                    }
                }
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
            
            Button("View Public Key"){
                let params = ["action": "get_public_key"]
                
                getPublicKey(params: params){ returnValues in
                    // Update the state on the main thread
                    DispatchQueue.main.async {
                        getPublicKeyStatus = returnValues["status"] as! Bool
                        getPublicKeyErrorMessage = returnValues["error"] as? String
                        publicKey = returnValues["public_key"] as! String
                    }
                }
            }
            
            Button("View Secret Key"){
                let username = UserDefaults.standard.string(forKey: "username")
                if let retrievedKey = retrieveSecretKey(username: username!) {
                    secretKey = retrievedKey
                    print("Retrieved secret key: \(secretKey)")
                } else {
                    print("Failed to retrieve secret key")
                }

            }
            
            Button("Generate Keys"){
                let params = ["action": "generate_keys"]
                
                generateKeys(params: params){ returnValues in
                    // Update the state on the main thread
                    DispatchQueue.main.async {
                        getPublicKeyStatus = returnValues["status"] as! Bool
                        getPublicKeyErrorMessage = returnValues["error"] as? String
                        publicKey = returnValues["public_key"] as! String
                        secretKey = returnValues["secret_key"] as! String
                    }
                }
            }
            
            Button("Save Public Key"){
                let params = ["public_key": publicKey, "action": "save_public_key"]
                savePublicKey(params: params){ success, error in
                    // Update the state on the main thread
                    DispatchQueue.main.async {
                        getPublicKeyStatus = success
                        getPublicKeyErrorMessage = error
                    }
                }
            }
            
            Button("Save Secret Key") {
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
            
            // TextField for username input
            TextField("Secret key:", text: $secretKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
            
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
                    
                    let username = UserDefaults.standard.string(forKey: "username")
                    if let retrievedKey = retrieveSecretKey(username: username!) {
                        secretKey = retrievedKey
                        print("Retrieved secret key: \(secretKey)")
                    } else {
                        print("Failed to retrieve secret key")
                    }
                    
                    let params = ["secret_key": secretKey, "action": "get_messages"]
                    
                    getMessages(params: params){ success, error, messages in
                        // Update the state on the main thread
                        DispatchQueue.main.async {
                            getMessagesStatus = success
                            getMessagesErrorMessage = error
                            messageList = messages
                        }
                    }
                }
                
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
func getMessages(params: [String: String], completion: @escaping (Bool, String?, [(String,String,String)]) -> Void) {
    
    let secretKey = params["secret_key"]
    let action = params["action"]
    
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
    let json: [String: Any] = ["username": username!, "token": token!, "action": action!, "secret_key": secretKey!]
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
            print("Messages:",decodedResponse.messages)
            
            // zip three lists of from, to, message into a single list
            var messages: [(from: String, to: String, message: String)] = []
            let numMessages = decodedResponse.messages.count
            if(numMessages > 0){
                for i in 0...numMessages-1 {
                    messages.append((from: decodedResponse.from[i], to: decodedResponse.to[i], message: decodedResponse.messages[i]))
                }
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
func getPublicKey(params: [String: String], completion: @escaping ([String: Any]) -> Void) {
    
    //action to send to API endpoint
    let action = params["action"]
    
    //return values as associative array
    var returnValues : [String: Any] = ["status": false, "error": "", "public_key": ""]
    
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
    guard let url = URL(string: "https://open-encrypt.com/inbox_ios.php") else {
        fatalError("Invalid URL")
    }

    // Create the URLRequest object
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Set the content type for JSON
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Create JSON data
    let json: [String: Any] = ["username": username!, "token": token!, "action": action!]
    let jsonData = try? JSONSerialization.data(withJSONObject: json)

    // Set HTTP body
    request.httpBody = jsonData
    
    // Create a URLSession data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(returnValues)
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print("Error: Invalid response or no data")
            returnValues["error"] = "Error: Invalid response or no data"
            completion(returnValues)
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
            returnValues["success"] = decodedResponse.status == "success"
            returnValues["error"] = decodedResponse.error
            returnValues["public_key"] = decodedResponse.public_key
            completion(returnValues)
        } catch {
            print("Error decoding JSON:", error)
            returnValues["error"] = "Error decoding JSON"
            completion(returnValues)
        }
    }

    // Start the task
    task.resume()
}

// Define the function with a completion handler
func generateKeys(params: [String: String], completion: @escaping ([String: Any]) -> Void) {
    
    let action = params["action"]
    var returnValues : [String: Any] = ["status": false, "error": "", "public_key": "","secret_key": ""]
    
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
    guard let url = URL(string: "https://open-encrypt.com/inbox_ios.php") else {
        fatalError("Invalid URL")
    }

    // Create the URLRequest object
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Set the content type for JSON
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Create JSON data
    let json: [String: Any] = ["username": username!, "token": token!, "action": action!]
    let jsonData = try? JSONSerialization.data(withJSONObject: json)

    // Set HTTP body
    request.httpBody = jsonData
    
    // Create a URLSession data task
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(returnValues)
            return
        }
        
        guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            print("Error: Invalid response or no data.")
            returnValues["error"] = "Invalid response or no data."
            completion(returnValues)
            return
        }
        
        // Define the shape and type of the JSON response
        struct MessagesResponse: Codable {
            let status: String
            let error: String?
            let public_key: String
            let secret_key: String
        }
        
        let decoder = JSONDecoder()
        do {
            let decodedResponse = try decoder.decode(MessagesResponse.self, from: data)
            print("Status: ", decodedResponse.status)
            print("Error: ", decodedResponse.error ?? "No error")
            
            // Determine success
            returnValues["status"] = decodedResponse.status == "success"
            returnValues["error"] = decodedResponse.error ?? "No error"
            
            //print the public and secret keys
            print("Gen Public Key:",decodedResponse.public_key)
            print("Gen Secret Key",decodedResponse.secret_key)
            
            returnValues["public_key"] = decodedResponse.public_key
            returnValues["secret_key"] = decodedResponse.secret_key
            
            completion(returnValues)
        } catch {
            print("Error decoding JSON:", error)
            returnValues["error"] = "Error decoding JSON."
            completion(returnValues)
        }
    }

    // Start the task
    task.resume()
}

// Define the function with a completion handler
func savePublicKey(params: [String: String], completion: @escaping (Bool, String?) -> Void) {
    
    let publicKey = params["public_key"]
    let action = params["action"]
    
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
        completion(false,"Invalid or no token.")
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
    let json: [String: Any] = ["username": username!, "token": token!, "action": action!, "public_key": publicKey!]
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
        struct SavePublicKeyResponse: Codable {
            let status: String
            let error: String?
        }
        
        let decoder = JSONDecoder()
        do {
            let decodedResponse = try decoder.decode(SavePublicKeyResponse.self, from: data)
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

// Define the function with a completion handler
func sendMessage(params: [String: String], completion: @escaping (Bool, String?) -> Void) {
    
    let message = params["message"]
    let recipient = params["recipient"]
    let action = params["action"]
    
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
        completion(false,"Invalid or no token.")
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
    let json: [String: Any] = ["username": username!, "token": token!, "action": action!,"message": message!, "recipient": recipient!]
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
        struct MessagesResponse: Codable {
            let status: String
            let error: String?
        }
        
        let decoder = JSONDecoder()
        do {
            let decodedResponse = try decoder.decode(MessagesResponse.self, from: data)
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
