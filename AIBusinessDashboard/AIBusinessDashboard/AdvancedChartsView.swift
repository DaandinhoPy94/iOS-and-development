//
//  AdvancedChartsView.swift
//  AIBusinessDashboard
//
//  Advanced chart types and data visualizations - SIMPLIFIED
//

import SwiftUI
import Charts

// MARK: - Main Advanced Charts View
struct AdvancedChartsView: View {
    @StateObject private var viewModel = AdvancedChartsViewModel()
    @State private var selectedChartType = ChartType.pieChart
    @State private var selectedTimeRange = "30D"
    @State private var animateCharts = false
    
    enum ChartType: String, CaseIterable {
        case pieChart = "Pie Chart"
        case heatmap = "Heatmap"
        case funnel = "Funnel"
        case multiAxis = "Multi-Axis"
        case stackedArea = "Stacked Area"
        case bubble = "Bubble Chart"
    }
    
    // MARK: - Simplified Heatmap Chart
    private var simplifiedHeatmapChart: some View {
        VStack(alignment: .leading) {
            Text("Sales Heatmap")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Hour × Day Sales Pattern")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Simple grid representation
            VStack(spacing: 2) {
                HStack {
                    Text("Hour")
                        .font(.caption2)
                        .frame(width: 30)
                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                ForEach(Array(stride(from: 9, through: 21, by: 3)), id: \.self) { hour in
                    HStack(spacing: 2) {
                        Text("\(hour):00")
                            .font(.caption2)
                            .frame(width: 30)
                        
                        ForEach(0..<7, id: \.self) { day in
                            let intensity = Double.random(in: 0.2...1.0)
                            Rectangle()
                                .fill(Color.blue.opacity(intensity))
                                .frame(height: 20)
                                .cornerRadius(2)
                        }
                    }
                }
            }
            .padding()
            
            // Legend
            HStack {
                Text("Low")
                    .font(.caption)
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.2), .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 15)
                    .cornerRadius(4)
                Text("High")
                    .font(.caption)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Simplified Funnel Chart
    private var simplifiedFunnelChart: some View {
        VStack(alignment: .leading) {
            Text("Conversion Funnel")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                ForEach(viewModel.funnelData, id: \.id) { stage in
                    HStack {
                        // Stage bar
                        RoundedRectangle(cornerRadius: 8)
                            .fill(stageColor(for: stage.stage).gradient)
                            .frame(width: CGFloat(stage.percentage / 100) * 250, height: 40)
                            .overlay(
                                HStack {
                                    Text(stage.stage)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                            )
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(stage.value))")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("\(Int(stage.percentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            
            // Conversion rates
            VStack(alignment: .leading, spacing: 8) {
                Text("Conversion Rates")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(0..<viewModel.funnelData.count-1, id: \.self) { index in
                    let current = viewModel.funnelData[index]
                    let next = viewModel.funnelData[index + 1]
                    let rate = (next.value / current.value) * 100
                    
                    HStack {
                        Text("\(current.stage) → \(next.stage)")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(rate))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(rate >= 60 ? .green : rate >= 40 ? .orange : .red)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private func stageColor(for stage: String) -> Color {
        switch stage {
        case "Visitors": return .blue
        case "Sign-ups": return .green
        case "Active Users": return .orange
        case "Customers": return .purple
        case "Repeat Buyers": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Chart Type Selector
                    chartTypeSelector
                    
                    // Selected Chart
                    Group {
                        switch selectedChartType {
                        case .pieChart:
                            CategoryPieChartView(data: viewModel.categoryData)
                        case .heatmap:
                            simplifiedHeatmapChart
                        case .funnel:
                            simplifiedFunnelChart
                        case .multiAxis:
                            multiAxisChart
                        case .stackedArea:
                            stackedAreaChart
                        case .bubble:
                            bubbleChart
                        }
                    }
                    .animation(.easeInOut(duration: 0.5), value: selectedChartType)
                }
                .padding()
            }
            .navigationTitle("Advanced Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(["7D", "30D", "90D", "1Y"], id: \.self) { range in
                            Button(range) {
                                selectedTimeRange = range
                                viewModel.loadData(for: range)
                            }
                        }
                    } label: {
                        Label(selectedTimeRange, systemImage: "calendar")
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateCharts = true
            }
            viewModel.loadData(for: selectedTimeRange)
        }
    }
    
    // MARK: - Chart Type Selector
    private var chartTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    ChartTypeCard(
                        type: type,
                        isSelected: selectedChartType == type,
                        action: { selectedChartType = type }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Simplified Multi-Axis Chart
    private var multiAxisChart: some View {
        VStack(alignment: .leading) {
            Text("Revenue vs Orders")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(viewModel.multiAxisData, id: \.id) { dataPoint in
                // Revenue bars
                BarMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Revenue", dataPoint.revenue)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
                
                // Orders line (scaled for visibility)
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Orders", dataPoint.orders * 100)
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Orders", dataPoint.orders * 100)
                )
                .foregroundStyle(.orange)
                .symbolSize(50)
            }
            .frame(height: 250)
            .padding()
            
            // Legend
            HStack(spacing: 20) {
                Label("Revenue (€)", systemImage: "square.fill")
                    .foregroundColor(.blue)
                Label("Orders (×100)", systemImage: "line.diagonal")
                    .foregroundColor(.orange)
            }
            .font(.caption)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Simplified Stacked Area Chart
    private var stackedAreaChart: some View {
        VStack(alignment: .leading) {
            Text("Revenue by Category")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(viewModel.stackedAreaData, id: \.id) { dataPoint in
                ForEach(dataPoint.categories, id: \.name) { category in
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Revenue", category.value)
                    )
                    .foregroundStyle(by: .value("Category", category.name))
                    .opacity(0.8)
                }
            }
            .frame(height: 250)
            .padding()
            
            // Category legend
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(viewModel.categories, id: \.self) { category in
                    HStack {
                        Circle()
                            .fill(categoryColor(for: category))
                            .frame(width: 10, height: 10)
                        Text(category)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Simplified Bubble Chart
    private var bubbleChart: some View {
        VStack(alignment: .leading) {
            Text("Product Performance")
                .font(.headline)
                .padding(.horizontal)
            
            Text("Size: Revenue • X: Units Sold • Y: Profit Margin")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Chart(viewModel.bubbleData, id: \.id) { product in
                PointMark(
                    x: .value("Units Sold", product.unitsSold),
                    y: .value("Profit Margin", product.profitMargin)
                )
                .foregroundStyle(by: .value("Category", product.category))
                .symbolSize(product.revenue / 100)
                .opacity(0.7)
            }
            .frame(height: 300)
            .chartXScale(domain: 0...1000)
            .chartYScale(domain: 0...50)
            .padding()
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private func categoryColor(for category: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .yellow]
        let index = viewModel.categories.firstIndex(of: category) ?? 0
        return colors[index % colors.count]
    }
}

// MARK: - Supporting Components
struct ChartTypeCard: View {
    let type: AdvancedChartsView.ChartType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: chartIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
        }
    }
    
    private var chartIcon: String {
        switch type {
        case .pieChart: return "chart.pie"
        case .heatmap: return "square.grid.3x3"
        case .funnel: return "triangle"
        case .multiAxis: return "chart.bar"
        case .stackedArea: return "chart.xyaxis.line"
        case .bubble: return "circle.grid.3x3"
        }
    }
}

#Preview {
    AdvancedChartsView()
}
