//
//  ContentView.swift
//  Motion X
//
//  Created by Qianxing Li on 9/28/23.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @State private var motionData = MotionData()
    @State private var motionDataPoints = MotionDataPoints()
    let motionManager = CMMotionManager()
    @State private var webSocketTask: URLSessionWebSocketTask? = nil
    @State private var serverAddress: String = "192.168.1.235"
    @State private var serverPort: String = "8080"
    @State private var isConnected: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    private let maxDataPoints = 100
    
    var body: some View {
        ScrollView {
            serverAddressField
            serverPortField
            connectionButton
            lineChart(for: motionDataPoints.roll, title: motionData.rollTitle)
            lineChart(for: motionDataPoints.pitch, title: motionData.pitchTitle)
            lineChart(for: motionDataPoints.yaw, title: motionData.yawTitle)
            lineChart(for: motionDataPoints.userAccelerationX, title: motionData.userAccelerationXTitle)
            lineChart(for: motionDataPoints.userAccelerationY, title: motionData.userAccelerationYTitle)
            lineChart(for: motionDataPoints.userAccelerationZ, title: motionData.userAccelerationZTitle)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .padding()
        .onAppear {
            startMotionUpdates()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    var serverAddressField: some View {
        TextField("Server Address", text: $serverAddress)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.title)
    }
    
    var serverPortField: some View {
        TextField("Server Port", text: $serverPort)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.title)
    }
    
    var connectionButton: some View {
        Button(action: toggleConnection) {
            Text(isConnected ? "Disconnect" : "Connect")
                .padding()
                .background(isConnected ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .font(.title)
        }
    }
    
    func lineChart(for dataPoints: [Double], title: String) -> some View {
        VStack {
            LineChartView(dataPoints: Array(dataPoints.suffix(maxDataPoints)))
                .frame(height: 100)
                .padding()
            Text(title)
        }
    }
    
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [self] (deviceMotion, error) in
            guard let deviceMotion = deviceMotion else { return }
            motionData.update(with: deviceMotion)
            motionDataPoints.append(motionData)
            if isConnected {
                sendData()
            }
        }
    }
    
    func sendData() {
        guard isConnected, let webSocketTask = webSocketTask, webSocketTask.state == .running else {
            print("WebSocket is not connected, stopping data sending.")
            isConnected = false
            webSocketTask?.cancel()
            return
        }
        
        if let data = try? JSONSerialization.data(withJSONObject: motionData.dictionary, options: []), let jsonString = String(data: data, encoding: .utf8) {
            webSocketTask.send(.string(jsonString)) { error in
                if let error = error {
                    print("WebSocket sending error: \(error)")
                }
            }
        }
    }
    
    func toggleConnection() {
        isConnected.toggle()
        isConnected ? connectWebSocket() : disconnectWebSocket()
    }
    
    func connectWebSocket() {
        let serverUrl = "ws://" + serverAddress + ":" + serverPort
        guard let url = URL(string: serverUrl) else {
            alertMessage = "Invalid URL: \(serverUrl)"
            showAlert = true
            isConnected = false
            return
        }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
    }
    
    func disconnectWebSocket() {
        webSocketTask?.cancel()
        webSocketTask = nil
    }
}

struct LineChartView: View {
    var dataPoints: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            if dataPoints.count > 1 {
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
            } else {
                Text("Waiting for data")
            }
        }
    }
}

struct MotionData {
    var roll: Double = 0
    var pitch: Double = 0
    var yaw: Double = 0
    var userAccelerationX: Double = 0
    var userAccelerationY: Double = 0
    var userAccelerationZ: Double = 0
    
    var rollTitle: String {
        "Roll: \(String(format: "%.2f", roll*180/Double.pi))°"
    }
    
    var pitchTitle: String {
        "Pitch: \(String(format: "%.2f", pitch*180/Double.pi))°"
    }
    
    var yawTitle: String {
        "Yaw: \(String(format: "%.2f", yaw*180/Double.pi))°"
    }
    
    var userAccelerationXTitle: String {
        "Acceleration X: \(String(format: "%.2f", userAccelerationX)) m/s²"
    }
    
    var userAccelerationYTitle: String {
        "Acceleration Y: \(String(format: "%.2f", userAccelerationY)) m/s²"
    }
    
    var userAccelerationZTitle: String {
        "Acceleration Z: \(String(format: "%.2f", userAccelerationZ)) m/s²"
    }
    
    var dictionary: [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        return [
            "roll": roll,
            "pitch": pitch,
            "yaw": yaw,
            "userAccelerationX": userAccelerationX,
            "userAccelerationY": userAccelerationY,
            "userAccelerationZ": userAccelerationZ,
            "timestamp": dateFormatter.string(from: Date())
        ]
    }
    
    mutating func update(with deviceMotion: CMDeviceMotion) {
        roll = deviceMotion.attitude.roll
        pitch = deviceMotion.attitude.pitch
        yaw = deviceMotion.attitude.yaw
        userAccelerationX = deviceMotion.userAcceleration.x
        userAccelerationY = deviceMotion.userAcceleration.y
        userAccelerationZ = deviceMotion.userAcceleration.z
    }
}

struct MotionDataPoints {
    var roll: [Double] = []
    var pitch: [Double] = []
    var yaw: [Double] = []
    var userAccelerationX: [Double] = []
    var userAccelerationY: [Double] = []
    var userAccelerationZ: [Double] = []
    
    mutating func append(_ motionData: MotionData) {
        roll.append(motionData.roll)
        pitch.append(motionData.pitch)
        yaw.append(motionData.yaw)
        userAccelerationX.append(motionData.userAccelerationX)
        userAccelerationY.append(motionData.userAccelerationY)
        userAccelerationZ.append(motionData.userAccelerationZ)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
