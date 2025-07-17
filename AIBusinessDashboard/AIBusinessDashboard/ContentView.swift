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

// Separate the original dashboard into its own view
struct DashboardView: View {
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
                    
                    // 🔥 NIEUWE SECTIE: Customer Quick Access
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Top Customers")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            NavigationLink("View All") {
                                CustomerListView()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        // Top 3 customers preview
                        VStack(spacing: 10) {
                            ForEach(0..<3) { index in
                                NavigationLink {
                                    CustomerAnalyticsView(customerId: 100 + index)
                                } label: {
                                    CustomerQuickCard(
                                        name: ["Sarah Johnson", "Mike Chen", "Emma Williams"][index],
                                        tier: ["Platinum", "Gold", "Silver"][index],
                                        value: [15420, 8750, 5230][index],
                                        riskLevel: ["Low", "Medium", "High"][index]
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
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

// CustomerQuickCard Helper View
struct CustomerQuickCard: View {
    let name: String
    let tier: String
    let value: Int
    let riskLevel: String
    
    var body: some View {
        HStack {
            // Customer avatar
            Circle()
                .fill(tierColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(tierColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(tier)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(tierColor.opacity(0.2))
                        )
                        .foregroundColor(tierColor)
                    
                    Text("€\(value)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Risk indicator
            HStack {
                Circle()
                    .fill(riskColor)
                    .frame(width: 8, height: 8)
                
                Text(riskLevel)
                    .font(.caption2)
                    .foregroundColor(riskColor)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    var tierColor: Color {
        switch tier {
        case "Platinum": return .purple
        case "Gold": return .orange
        default: return .gray
        }
    }
    
    var riskColor: Color {
        switch riskLevel {
        case "High": return .red
        case "Medium": return .orange
        default: return .green
        }
    }
}

// Main ContentView with TabView
struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "gauge.medium")
                    Text("Dashboard")
                }
            
            ChartsView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Charts")
                }
            
            NavigationView {
                CustomerListView()
            }
            .tabItem {
                Image(systemName: "person.3.fill")
                Text("Customers")
            }
            
            LiveDataView()
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Live")
                }
            
            NotificationSettingsView()
                .tabItem {
                    Image(systemName: "bell.badge")
                    Text("Alerts")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
