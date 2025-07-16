//
//  APIService.swift
//  AIBusinessDashboard
//
//  Created by Daan van der Ster on 11/07/2025.
//

import Foundation

@MainActor
class APIService: ObservableObject {
    private let baseURL = "http://localhost:8000"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchDashboardData() async throws -> DashboardData {
        isLoading = true
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // For now, return enhanced mock data that looks realistic
        let mockData = DashboardData(
            message: nil,
            timestamp: nil,
            status: nil,
            revenueForecast: Double.random(in: 120000...130000),
            modelAccuracy: 0.982,
            activeCustomers: Int.random(in: 1200...1300),
            predictionsToday: Int.random(in: 300...400),
            lastUpdated: Date()
        )
        
        isLoading = false
        return mockData
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}
