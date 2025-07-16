//
//  DashboardData.swift
//  AIBusinessDashboard
//
//  Created by Daan van der Ster on 11/07/2025.
//

import Foundation

struct DashboardData: Codable {
    let message: String?
    let timestamp: String?
    let status: String?
    
    // Keep your original properties for backward compatibility
    let revenueForecast: Double?
    let modelAccuracy: Double?
    let activeCustomers: Int?
    let predictionsToday: Int?
    let lastUpdated: Date?
    
    static let mockData = DashboardData(
        message: "Test",
        timestamp: "2025-07-11T00:30:00Z",
        status: "working",
        revenueForecast: 125000.0,
        modelAccuracy: 0.982,
        activeCustomers: 1247,
        predictionsToday: 342,
        lastUpdated: Date()
    )
}

struct MetricData {
    let title: String
    let value: String
    let change: String
    let icon: String
    let isPositive: Bool
}

extension DashboardData {
    var metrics: [MetricData] {
        return [
            MetricData(
                title: "Revenue Forecast",
                value: "€\(Int(revenueForecast ?? 125000).formatted())",
                change: "+12.5%",
                icon: "chart.line.uptrend.xyaxis",
                isPositive: true
            ),
            MetricData(
                title: "Model Accuracy",
                value: "\(Int((modelAccuracy ?? 0.982) * 100))%",
                change: "+0.3%",
                icon: "brain.head.profile",
                isPositive: true
            ),
            MetricData(
                title: "Active Customers",
                value: "\(activeCustomers ?? 1247)",
                change: "+8.1%",
                icon: "person.3.fill",
                isPositive: true
            ),
            MetricData(
                title: "Predictions",
                value: "\(predictionsToday ?? 342)",
                change: "Today",
                icon: "sparkles",
                isPositive: true
            )
        ]
    }
}
