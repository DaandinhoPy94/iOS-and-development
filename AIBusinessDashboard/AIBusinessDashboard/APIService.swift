//
//  APIService.swift
//  AIBusinessDashboard
//
//  Created by Daan van der Ster on 11/07/2025.
//

import Foundation

// API Response models
struct APIResponse: Codable {
    let status: String
    let timestamp: String
    let message: String?
    let data: APIData
}

struct APIData: Codable {
    let metrics: APIMetrics
    let ml_insights: MLInsights
}

struct APIMetrics: Codable {
    let totalCustomers: Int
    let activeCustomers: Int
    let totalRevenue: Double
    let avgOrderValue: Double
    let totalOrders: Int
}

struct MLInsights: Codable {
    let modelAccuracy: Double
    let highRiskCustomers: Int
    let predictionsToday: Int
    let avgChurnRisk: Double
}

@MainActor
class APIService: ObservableObject {
    private let baseURL = "https://ios-and-development-production.up.railway.app"
    
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchDashboardData() async throws -> DashboardData {
        isLoading = true
        errorMessage = nil
    
        guard let url = URL(string: "\(baseURL)/api/v1/dashboard/") else {
            isLoading = false
            throw APIError.invalidURL
        }
    
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200 else {
                isLoading = false
                throw APIError.invalidResponse
            }
            
            // Parse the API response
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            
            // Convert API response to DashboardData
            let dashboardData = DashboardData(
                message: apiResponse.message,
                timestamp: apiResponse.timestamp,
                status: apiResponse.status,
                revenueForecast: apiResponse.data.metrics.totalRevenue,
                modelAccuracy: apiResponse.data.ml_insights.modelAccuracy,
                activeCustomers: apiResponse.data.metrics.activeCustomers,
                predictionsToday: apiResponse.data.ml_insights.predictionsToday,
                lastUpdated: Date()
            )
            
            isLoading = false
            return dashboardData
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw APIError.decodingError
        }
    }
}    

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}
