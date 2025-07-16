//
//  ContentView.swift
//  AIBusinessDashboard
//
//  Created by Daan van der Ster on 11/07/2025.
//

import SwiftUI

struct MetricCard: View {
    let metric: MetricData
    @State private var animateValue = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                Spacer()
                Text(metric.change)
                    .font(.caption)
                    .foregroundColor(metric.isPositive ? .green : .red)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(metric.isPositive ? .green.opacity(0.1) : .red.opacity(0.1))
                    )
            }
            
            Text(metric.value)
                .font(.title2)
                .fontWeight(.bold)
                .scaleEffect(animateValue ? 1.05 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateValue)
            
            Text(metric.title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .onAppear {
            animateValue = true
        }
    }
}

struct ContentView: View {
    @StateObject private var apiService = APIService()
    @State private var dashboardData: DashboardData = DashboardData.mockData
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    HStack {
                        VStack(alignment: .leading) {
                            Text("AI Business Dashboard")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Real-time Insights")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        HStack {
                            if apiService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 12, height: 12)
                            }
                            Text(apiService.isLoading ? "LOADING" : "LIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Metrics Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        
                        ForEach(dashboardData.metrics.indices, id: \.self) { index in
                            MetricCard(metric: dashboardData.metrics[index])
                        }
                    }
                    .padding(.horizontal)
                    
                    // Refresh Button
                    Button("Refresh Data") {
                        Task {
                            do {
                                dashboardData = try await apiService.fetchDashboardData()
                            } catch {
                                print("Error fetching data: \(error)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    Spacer()
                }
            }
            .refreshable {
                // Pull to refresh functionality
                do {
                    dashboardData = try await apiService.fetchDashboardData()
                } catch {
                    print("Error refreshing data: \(error)")
                }
            }
            .navigationBarHidden(true)
            .task {
                // Load data when view appears
                do {
                    dashboardData = try await apiService.fetchDashboardData()
                } catch {
                    print("Error loading initial data: \(error)")
                }
            }
            .onAppear {
                // Start auto-refresh timer (every 30 seconds)
                refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                    Task {
                        do {
                            dashboardData = try await apiService.fetchDashboardData()
                        } catch {
                            print("Auto-refresh failed: \(error)")
                        }
                    }
                }
            }
            .onDisappear {
                refreshTimer?.invalidate()
            }
        }
    }
}

#Preview {
    ContentView()
}
