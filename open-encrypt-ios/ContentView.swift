//
//  ContentView.swift
//  open-encrypt-ios
//
//  Created by Jackson Walters on 9/11/24.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State var button_clicked: Bool = false
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Welcome to Open Encrypt")
            Button("Sign In", action: {
                send_http_request()
                button_clicked = !button_clicked
            })
            if button_clicked {
                Text("Button clicked!")
            }
        }
        .padding()
    }
}

//function send HTTP post request
func send_http_request(){

    // Define the URL of the endpoint
    guard let url = URL(string: "https://open-encrypt.com/login_ios.php") else {
        fatalError("Invalid URL")
    }

    // Create the URLRequest object
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    // Define the parameters
    let parameters = ["username": "jackson"]

    // Convert parameters to JSON data
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
    } catch {
        print("Error: Unable to serialize parameters")
        return
    }

    // Set the content type to JSON
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
        
        // Handle the response data if needed
        print("Success: \(String(data: data, encoding: .utf8) ?? "No data")")
    }

    // Start the task
    task.resume()
}

#Preview {
    ContentView()
}
