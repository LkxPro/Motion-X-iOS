//
//  ContentView.swift
//  Motion X
//
//  Created by Qianxing Li on 9/28/23.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @State private var roll: Double = 0
    @State private var pitch: Double = 0
    @State private var yaw: Double = 0
    let motionManager = CMMotionManager()
    @State private var webSocketTask: URLSessionWebSocketTask? = nil
    @State private var serverAddress: String = "192.168.1.235"
    @State private var serverPort: String = "8080"
    @State private var wsSent: Bool = false
    @State private var rollDataPoints: [Double] = []
    private let maxDataPoints = 100
    
    var body: some View {
        VStack {
            TextField("Server Address", text: $serverAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.done)
            TextField("Server Port", text: $serverPort) // Fixed label
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.done)
            
            if !wsSent {
                Button("Connect") {
                    wsSent = true
                    connectWebSocket()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            else {
                Button("Disconnect") {
                    wsSent = false
                    webSocketTask?.cancel()
                    webSocketTask = nil // Close WebSocket task
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Text("Roll: \(roll)")
            Text("Pitch: \(pitch)")
            Text("Yaw: \(yaw)")
            LineChartView(dataPoints: Array(rollDataPoints.suffix(maxDataPoints)))
                            .frame(height: 200)
                            .padding()
        }
        .font(.title)
        .padding()
        .onAppear {
            startMotionUpdates()
        }
    }
    
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            print("DeviceMotion is Available")
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { (deviceMotion, error) in
                guard let deviceMotion = deviceMotion else { return }
                self.roll = deviceMotion.attitude.roll
                self.pitch = deviceMotion.attitude.pitch
                self.yaw = deviceMotion.attitude.yaw
                
                self.rollDataPoints.append(self.roll) // Append roll value to rollDataPoints array
                
                let motionData: [String: Double] = [
                    "roll": self.roll,
                    "pitch": self.pitch,
                    "yaw": self.yaw
                ]
                if wsSent {
                    if let webSocketTask = self.webSocketTask, webSocketTask.state == .running {
                        if let data = try? JSONEncoder().encode(motionData),
                           let jsonString = String(data: data, encoding: .utf8) {
                            self.webSocketTask?.send(.string(jsonString)) { error in
                                if let error = error {
                                    print("WebSocket sending error: \(error)")
                                }
                            }
                        }
                    }
                    else {
                        print("WebSocket is not connected, stopping data sending.")
                        self.wsSent = false
                        self.webSocketTask?.cancel() // Close WebSocket task
                        self.webSocketTask = nil
                    }
                }
            }
        }
        else {
            print("DeviceMotion is Not Available") // Fixed print statement
        }
    }
    
    func connectWebSocket() {
        let serverUrl = "ws://" + serverAddress + ":" + serverPort
        guard let url = URL(string: serverUrl) else {
            print("Invalid URL: ", serverUrl)
            wsSent = false
            return
        }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
    }
}

struct LineChartView: View {
    var dataPoints: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                for i in dataPoints.indices {
                    let xPosition = geometry.size.width * CGFloat(i) / CGFloat(dataPoints.count - 1)
                    let yPosition = geometry.size.height * (1 - CGFloat((dataPoints[i] + .pi) / (2 * .pi)))
                    let point = CGPoint(x: xPosition, y: yPosition)
                    if i == 0 {
                        path.move(to: point)
                    } else {
                        path.addLine(to: point)
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
