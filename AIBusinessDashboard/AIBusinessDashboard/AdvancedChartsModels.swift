//
//  AdvancedChartsModels.swift
//  AIBusinessDashboard
//
//  Data models and view model for advanced charts
//

import Foundation
import SwiftUI

// MARK: - Data Models (FIXED: All Identifiable)

struct PieChartData: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let percentage: Double
}

struct HeatmapData: Identifiable {
    let id = UUID()
    let hour: Int
    let day: Int
    let value: Double
}

struct FunnelData: Identifiable {
    let id = UUID()
    let stage: String
    let value: Double
    let percentage: Double
}

struct FlowData {
    let nodes: [FlowNodeData]
    let connections: [FlowConnectionData]
    let stages: Int
    let totalFlow: Double
    let overallConversion: Double
    let maxConnectionValue: Double
}

struct FlowNodeData: Identifiable {
    let id: String
    let name: String
    let value: Double
    let stage: Int
    let position: Double
}

struct FlowConnectionData: Identifiable {
    let id: String
    let from: String
    let to: String
    let value: Double
}

struct RadarChartData {
    let categories: [String]
    let series: [RadarSeries]
    let maxValue: Double
}

struct RadarSeries: Identifiable {
    let id = UUID()
    let name: String
    let values: [Double]
}

struct TreemapData: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let percentage: Double
    let category: String
}

struct MultiAxisDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let revenue: Double
    let orders: Int
}

struct StackedAreaDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let categories: [CategoryValue]
}

struct CategoryValue: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
}

struct BubbleDataPoint: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let unitsSold: Double
    let profitMargin: Double
    let revenue: Double
}

// MARK: - View Model
@MainActor
class AdvancedChartsViewModel: ObservableObject {
    @Published var categoryData: [PieChartData] = []
    @Published var heatmapData: [[HeatmapData]] = []
    @Published var funnelData: [FunnelData] = []
    @Published var flowData: FlowData = FlowData(
        nodes: [],
        connections: [],
        stages: 0,
        totalFlow: 0,
        overallConversion: 0,
        maxConnectionValue: 0
    )
    @Published var radarData: RadarChartData = RadarChartData(
        categories: [],
        series: [],
        maxValue: 100
    )
    @Published var treemapData: [TreemapData] = []
    @Published var multiAxisData: [MultiAxisDataPoint] = []
    @Published var stackedAreaData: [StackedAreaDataPoint] = []
    @Published var bubbleData: [BubbleDataPoint] = []
    
    let categories = ["Electronics", "Clothing", "Home", "Sports", "Books", "Food"]
    
    func loadData(for timeRange: String) {
        // Load all chart data
        loadPieChartData()
        loadHeatmapData()
        loadFunnelData()
        loadFlowData()
        loadRadarData()
        loadTreemapData()
        loadMultiAxisData()
        loadStackedAreaData()
        loadBubbleData()
    }
    
    private func loadPieChartData() {
        let values = [45000, 32000, 28000, 21000, 15000, 9000]
        let total = values.reduce(0, +)
        
        categoryData = zip(categories, values).map { category, value in
            PieChartData(
                category: category,
                value: Double(value),
                percentage: Double(value) / Double(total) * 100
            )
        }
    }
    
    private func loadHeatmapData() {
        heatmapData = (0..<24).map { hour in
            (0..<7).map { day in
                HeatmapData(
                    hour: hour,
                    day: day,
                    value: Double.random(in: 0...100) * (hour >= 9 && hour <= 21 ? 2 : 0.5)
                )
            }
        }
    }
    
    private func loadFunnelData() {
        let stages = [
            ("Visitors", 10000),
            ("Sign-ups", 3500),
            ("Active Users", 2800),
            ("Customers", 1200),
            ("Repeat Buyers", 450)
        ]
        
        funnelData = stages.map { stage, value in
            FunnelData(
                stage: stage,
                value: Double(value),
                percentage: Double(value) / Double(stages[0].1) * 100
            )
        }
    }
    
    private func loadFlowData() {
        let nodes = [
            FlowNodeData(id: "start", name: "Start", value: 1000, stage: 0, position: 0.5),
            FlowNodeData(id: "browse", name: "Browse", value: 800, stage: 1, position: 0.3),
            FlowNodeData(id: "search", name: "Search", value: 600, stage: 1, position: 0.7),
            FlowNodeData(id: "product", name: "Product View", value: 700, stage: 2, position: 0.5),
            FlowNodeData(id: "cart", name: "Add to Cart", value: 400, stage: 3, position: 0.5),
            FlowNodeData(id: "checkout", name: "Checkout", value: 350, stage: 4, position: 0.5),
            FlowNodeData(id: "purchase", name: "Purchase", value: 300, stage: 5, position: 0.5)
        ]
        
        let connections = [
            FlowConnectionData(id: "1", from: "start", to: "browse", value: 500),
            FlowConnectionData(id: "2", from: "start", to: "search", value: 500),
            FlowConnectionData(id: "3", from: "browse", to: "product", value: 400),
            FlowConnectionData(id: "4", from: "search", to: "product", value: 300),
            FlowConnectionData(id: "5", from: "product", to: "cart", value: 400),
            FlowConnectionData(id: "6", from: "cart", to: "checkout", value: 350),
            FlowConnectionData(id: "7", from: "checkout", to: "purchase", value: 300)
        ]
        
        flowData = FlowData(
            nodes: nodes,
            connections: connections,
            stages: 6,
            totalFlow: 1000,
            overallConversion: 30,
            maxConnectionValue: 500
        )
    }
    
    private func loadRadarData() {
        let categories = ["Sales", "Customer Satisfaction", "Efficiency", "Innovation", "Quality", "Growth"]
        
        let series = [
            RadarSeries(name: "Current", values: [85, 92, 78, 65, 88, 73]),
            RadarSeries(name: "Target", values: [90, 95, 85, 80, 90, 85]),
            RadarSeries(name: "Previous", values: [75, 88, 72, 60, 85, 65])
        ]
        
        radarData = RadarChartData(
            categories: categories,
            series: series,
            maxValue: 100
        )
    }
    
    private func loadTreemapData() {
        let products = [
            ("iPhone 15", 35000),
            ("MacBook Pro", 28000),
            ("AirPods", 15000),
            ("iPad Pro", 18000),
            ("Apple Watch", 12000),
            ("Accessories", 8000),
            ("Services", 14000)
        ]
        
        let total = products.reduce(0) { $0 + $1.1 }
        
        treemapData = products.map { name, value in
            TreemapData(
                name: name,
                value: Double(value),
                percentage: Double(value) / Double(total) * 100,
                category: "Electronics"
            )
        }
    }
    
    private func loadMultiAxisData() {
        multiAxisData = (0..<30).map { day in
            MultiAxisDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
                revenue: Double.random(in: 10000...50000),
                orders: Int.random(in: 50...200)
            )
        }.reversed()
    }
    
    private func loadStackedAreaData() {
        stackedAreaData = (0..<30).map { day in
            StackedAreaDataPoint(
                date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
                categories: categories.map { category in
                    CategoryValue(
                        name: category,
                        value: Double.random(in: 1000...10000)
                    )
                }
            )
        }.reversed()
    }
    
    private func loadBubbleData() {
        bubbleData = (0..<20).map { index in
            BubbleDataPoint(
                name: "Product \(index + 1)",
                category: categories.randomElement()!,
                unitsSold: Double.random(in: 100...1000),
                profitMargin: Double.random(in: 10...40),
                revenue: Double.random(in: 10000...100000)
            )
        }
    }
}
