//
//  WebSocketManager.swift
//  AIBusinessDashboard
//
//  Real-time WebSocket connection for live data streaming
//

import Foundation
import Combine
import SwiftUI 

// WebSocket Message Types
struct WebSocketMessage: Codable {
    let type: MessageType
    let data: MessageData
    let timestamp: String
    
    enum MessageType: String, Codable {
        case metrics = "metrics"
        case revenue = "revenue"
        case alert = "alert"
        case customerUpdate = "customer_update"
        case orderPlaced = "order_placed"
    }
}

struct MessageData: Codable {
    // Metrics update
    let totalRevenue: Double?
    let activeCustomers: Int?
    let ordersToday: Int?
    
    // Revenue update
    let revenueToday: Double?
    let lastHourRevenue: Double?
    
    // Alert
    let alertTitle: String?
    let alertMessage: String?
    let alertSeverity: String?
    
    // Order update
    let orderId: Int?
    let orderAmount: Double?
    let customerName: String?
}

// Live Data Models
struct LiveMetrics: Codable {
    let ordersToday: Int
    let revenueToday: Double
    let customersToday: Int
    let ordersLastHour: Int
    let timestamp: String
}

@MainActor
class WebSocketManager: NSObject, ObservableObject {
    static let shared = WebSocketManager()
    
    // Published properties for UI updates
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var liveMetrics: LiveMetrics?
    @Published var recentAlerts: [WebSocketMessage] = []
    @Published var realtimeRevenue: Double = 0.0
    
    // WebSocket properties
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private let baseURL = "wss://ios-and-development-production.up.railway.app/ws"
    // For local testing: "ws://localhost:8000/ws"
    
    // Reconnection properties
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 5.0
    
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard webSocketTask == nil else {
            print("⚠️ WebSocket already connected")
            return
        }
        
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid WebSocket URL")
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        isConnected = true
        connectionStatus = "Connecting..."
        reconnectAttempts = 0
        
        // Start receiving messages
        receiveMessage()
        
        // Start ping timer to keep connection alive
        startPingTimer()
        
        print("🔌 WebSocket connecting to: \(baseURL)")
    }
    
    func disconnect() {
        stopPingTimer()
        stopReconnectTimer()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        isConnected = false
        connectionStatus = "Disconnected"
        
        print("🔌 WebSocket disconnected")
    }
    
    // MARK: - Message Handling
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                self.handleConnectionError()
                
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleTextMessage(text)
                case .data(let data):
                    self.handleDataMessage(data)
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self.receiveMessage()
            }
        }
    }
    
    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            
            DispatchQueue.main.async {
                self.processMessage(message)
            }
        } catch {
            print("❌ Failed to decode WebSocket message: \(error)")
        }
    }
    
    private func handleDataMessage(_ data: Data) {
        // Handle binary messages if needed
        print("📦 Received binary data: \(data.count) bytes")
    }
    
    private func processMessage(_ message: WebSocketMessage) {
        switch message.type {
        case .metrics:
            updateMetrics(from: message.data)
            
        case .revenue:
            updateRevenue(from: message.data)
            
        case .alert:
            handleAlert(message)
            
        case .customerUpdate:
            handleCustomerUpdate(message)
            
        case .orderPlaced:
            handleNewOrder(message)
        }
    }
    
    // MARK: - Data Updates
    
    private func updateMetrics(from data: MessageData) {
        if let revenue = data.totalRevenue {
            self.realtimeRevenue = revenue
        }
        
        // Create live metrics update
        if let ordersToday = data.ordersToday,
           let revenueToday = data.revenueToday ?? data.totalRevenue,
           let customersToday = data.activeCustomers {
            
            self.liveMetrics = LiveMetrics(
                ordersToday: ordersToday,
                revenueToday: revenueToday,
                customersToday: customersToday,
                ordersLastHour: 0,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        connectionStatus = "Live"
    }
    
    private func updateRevenue(from data: MessageData) {
        if let todayRevenue = data.revenueToday {
            self.realtimeRevenue = todayRevenue
        }
    }
    
    private func handleAlert(_ message: WebSocketMessage) {
        // Add to recent alerts
        recentAlerts.insert(message, at: 0)
        
        // Keep only last 10 alerts
        if recentAlerts.count > 10 {
            recentAlerts.removeLast()
        }
        
        // Trigger local notification if app is in background
        if let title = message.data.alertTitle,
           let body = message.data.alertMessage {
            triggerLocalNotification(title: title, body: body)
        }
    }
    
    private func handleCustomerUpdate(_ message: WebSocketMessage) {
        print("👤 Customer update received")
        // Post notification for views to update
        NotificationCenter.default.post(
            name: .customerDataUpdated,
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    private func handleNewOrder(_ message: WebSocketMessage) {
        print("🛍️ New order placed!")
        
        // Update metrics if we have order data
        if let amount = message.data.orderAmount {
            self.realtimeRevenue += amount
        }
        
        // Post notification
        NotificationCenter.default.post(
            name: .newOrderReceived,
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    // MARK: - Connection Maintenance
    
    private func startPingTimer() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                print("❌ Ping failed: \(error)")
                self?.handleConnectionError()
            } else {
                print("✅ Ping successful")
            }
        }
    }
    
    // MARK: - Sending Messages
    
    func sendMessage(_ message: WebSocketMessage) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        guard let string = String(data: data, encoding: .utf8) else { return }
        
        webSocketTask?.send(.string(string)) { error in
            if let error = error {
                print("❌ Send error: \(error)")
            }
        }
    }
    
    func subscribeToUpdates(types: [WebSocketMessage.MessageType]) {
        let subscription = [
            "action": "subscribe",
            "types": types.map { $0.rawValue }
        ] as [String : Any]
        
        guard let data = try? JSONSerialization.data(withJSONObject: subscription) else { return }
        guard let string = String(data: data, encoding: .utf8) else { return }
        
        webSocketTask?.send(.string(string)) { error in
            if let error = error {
                print("❌ Subscribe error: \(error)")
            } else {
                print("✅ Subscribed to: \(types)")
            }
        }
    }
    
    // MARK: - Error Handling & Reconnection
    
    private func handleConnectionError() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Reconnecting..."
        }
        
        stopPingTimer()
        webSocketTask = nil
        
        // Attempt reconnection
        attemptReconnect()
    }
    
    private func attemptReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            DispatchQueue.main.async {
                self.connectionStatus = "Connection Failed"
            }
            return
        }
        
        reconnectAttempts += 1
        print("🔄 Reconnection attempt \(reconnectAttempts)/\(maxReconnectAttempts)")
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectDelay, repeats: false) { [weak self] _ in
            self?.connect()
        }
    }
    
    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Notifications
    
    private func triggerLocalNotification(title: String, body: String) {
        Task {
            await NotificationManager().sendInstantAlert(
                title: title,
                body: body,
                category: "WEBSOCKET_ALERT"
            )
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket connected")
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectionStatus = "Connected"
            self.reconnectAttempts = 0
        }
        
        // Subscribe to all update types
        subscribeToUpdates(types: [.metrics, .revenue, .alert, .orderPlaced])
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("🔌 WebSocket closed: \(closeCode)")
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionStatus = "Disconnected"
        }
        
        // Attempt reconnection unless explicitly closed
        if closeCode != .goingAway {
            handleConnectionError()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let customerDataUpdated = Notification.Name("customerDataUpdated")
    static let newOrderReceived = Notification.Name("newOrderReceived")
    static let webSocketStatusChanged = Notification.Name("webSocketStatusChanged")
}

// MARK: - SwiftUI Integration View

struct LiveDataView: View {
    @StateObject private var webSocket = WebSocketManager.shared
    @State private var sparkleAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Status
            HStack {
                Circle()
                    .fill(webSocket.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                Text(webSocket.connectionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if webSocket.isConnected {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.green)
                        .scaleEffect(sparkleAnimation ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: sparkleAnimation)
                }
            }
            .padding(.horizontal)
            
            // Live Metrics
            if let metrics = webSocket.liveMetrics {
                VStack(spacing: 15) {
                    HStack {
                        LiveMetricCard(
                            title: "Orders Today",
                            value: "\(metrics.ordersToday)",
                            icon: "cart.fill",
                            color: .blue
                        )
                        
                        LiveMetricCard(
                            title: "Revenue Today",
                            value: "€\(Int(metrics.revenueToday).formatted())",
                            icon: "eurosign.circle.fill",
                            color: .green
                        )
                    }
                    
                    HStack {
                        LiveMetricCard(
                            title: "Active Customers",
                            value: "\(metrics.customersToday)",
                            icon: "person.3.fill",
                            color: .orange
                        )
                        
                        LiveMetricCard(
                            title: "Last Hour",
                            value: "\(metrics.ordersLastHour) orders",
                            icon: "clock.fill",
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Recent Alerts
            if !webSocket.recentAlerts.isEmpty {
                VStack(alignment: .leading) {
                    Text("Recent Alerts")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(webSocket.recentAlerts, id: \.timestamp) { alert in
                                AlertRow(alert: alert)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            webSocket.connect()
            sparkleAnimation = true
        }
        .onDisappear {
            webSocket.disconnect()
        }
    }
}

struct LiveMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                
                // Live indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(), value: isAnimating)
            }
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct AlertRow: View {
    let alert: WebSocketMessage
    
    var body: some View {
        HStack {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
            
            VStack(alignment: .leading) {
                Text(alert.data.alertTitle ?? "Alert")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(alert.data.alertMessage ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timeAgo(from: alert.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    var severityIcon: String {
        switch alert.data.alertSeverity {
        case "high": return "exclamationmark.triangle.fill"
        case "medium": return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    var severityColor: Color {
        switch alert.data.alertSeverity {
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }
    
    func timeAgo(from timestamp: String) -> String {
        // Convert ISO timestamp to relative time
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else { return "" }
        
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval/60))m ago" }
        return "\(Int(interval/3600))h ago"
    }
}
