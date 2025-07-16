//
//  ChartsView.swift
//  AIBusinessDashboard
//
//  Created by Daan van der Ster on 17/07/2025.
//

import SwiftUI
import Charts

struct RevenueDataPoint {
    let date: String
    let revenue: Double
    let orders: Int
}

struct ChartsView: View {
    @StateObject private var apiService = APIService()
    @State private var revenueData: [RevenueDataPoint] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header
                    headerView
                    
                    // Revenue Trend Chart
                    revenueTrendChart
                    
                    // Daily Orders Chart
                    dailyOrdersChart
                    
                    // Summary Stats
                    summaryStatsGrid
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await loadChartData()
            }
            .task {
                await loadChartData()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Revenue Analytics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Live Production Data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Circle()
                .fill(.green)
                .frame(width: 12, height: 12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Revenue Trend Chart
    private var revenueTrendChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Revenue Trend (30 Days)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if isLoading {
                loadingView(height: 200)
            } else {
                revenueChart
            }
        }
        .padding()
        .background(chartCardBackground)
        .padding(.horizontal)
    }
    
    // MARK: - Revenue Chart
    private var revenueChart: some View {
        Chart(revenueData, id: \.date) { dataPoint in
            // Line Mark
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Revenue", dataPoint.revenue)
            )
            .foregroundStyle(lineGradient)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            // Area Mark
            AreaMark(
                x: .value("Date", dataPoint.date),
                y: .value("Revenue", dataPoint.revenue)
            )
            .foregroundStyle(areaGradient)
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: 7)) { _ in
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisTick()
                AxisValueLabel {
                    if let revenue = value.as(Double.self) {
                        Text("€\(Int(revenue/1000))K")
                    }
                }
            }
        }
    }
    
    // MARK: - Daily Orders Chart
    private var dailyOrdersChart: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Daily Orders")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if isLoading {
                loadingView(height: 150)
            } else {
                ordersChart
            }
        }
        .padding()
        .background(chartCardBackground)
        .padding(.horizontal)
    }
    
    // MARK: - Orders Chart
    private var ordersChart: some View {
        Chart(revenueData, id: \.date) { dataPoint in
            BarMark(
                x: .value("Date", dataPoint.date),
                y: .value("Orders", dataPoint.orders)
            )
            .foregroundStyle(barGradient)
            .cornerRadius(4)
        }
        .frame(height: 150)
        .chartXAxis {
            AxisMarks(values: .stride(by: 5)) { _ in
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
    }
    
    // MARK: - Summary Stats Grid
    private var summaryStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            
            StatCard(
                title: "Total Revenue",
                value: "€\(Int(totalRevenue).formatted())",
                icon: "eurosign.circle.fill",
                color: .blue
            )
            
            StatCard(
                title: "Total Orders",
                value: "\(totalOrders)",
                icon: "bag.fill",
                color: .green
            )
            
            StatCard(
                title: "Avg Daily Revenue",
                value: "€\(Int(avgDailyRevenue).formatted())",
                icon: "chart.bar.fill",
                color: .orange
            )
            
            StatCard(
                title: "Peak Day",
                value: peakDay,
                icon: "crown.fill",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Views
    private func loadingView(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
            .frame(height: height)
            .overlay(
                ProgressView()
                    .scaleEffect(1.2)
            )
    }
    
    private var chartCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Gradients
    private var lineGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.blue, .purple]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var areaGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.1)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var barGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.green, .mint]),
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    // MARK: - Computed Properties
    private var totalRevenue: Double {
        revenueData.reduce(0) { $0 + $1.revenue }
    }
    
    private var totalOrders: Int {
        revenueData.reduce(0) { $0 + $1.orders }
    }
    
    private var avgDailyRevenue: Double {
        revenueData.isEmpty ? 0 : totalRevenue / Double(revenueData.count)
    }
    
    private var peakDay: String {
        revenueData.max(by: { $0.revenue < $1.revenue })?.date.suffix(5).description ?? "N/A"
    }
    
    // MARK: - Data Loading
    private func loadChartData() async {
        isLoading = true
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        revenueData = [
            RevenueDataPoint(date: "2025-07-01", revenue: 13980.52, orders: 4),
            RevenueDataPoint(date: "2025-07-02", revenue: 32360.35, orders: 7),
            RevenueDataPoint(date: "2025-07-03", revenue: 11819.31, orders: 6),
            RevenueDataPoint(date: "2025-07-04", revenue: 18745.67, orders: 8),
            RevenueDataPoint(date: "2025-07-05", revenue: 25432.18, orders: 12),
            RevenueDataPoint(date: "2025-07-06", revenue: 29876.43, orders: 15),
            RevenueDataPoint(date: "2025-07-07", revenue: 22154.87, orders: 9),
            RevenueDataPoint(date: "2025-07-08", revenue: 31245.92, orders: 14),
            RevenueDataPoint(date: "2025-07-09", revenue: 28567.34, orders: 11),
            RevenueDataPoint(date: "2025-07-10", revenue: 35678.91, orders: 16),
            RevenueDataPoint(date: "2025-07-11", revenue: 27983.45, orders: 13),
            RevenueDataPoint(date: "2025-07-12", revenue: 33421.76, orders: 18),
            RevenueDataPoint(date: "2025-07-13", revenue: 29654.82, orders: 12),
            RevenueDataPoint(date: "2025-07-14", revenue: 41234.65, orders: 21),
            RevenueDataPoint(date: "2025-07-15", revenue: 38976.54, orders: 19),
            RevenueDataPoint(date: "2025-07-16", revenue: 42567.89, orders: 22)
        ]
        
        isLoading = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
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
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    ChartsView()
}
