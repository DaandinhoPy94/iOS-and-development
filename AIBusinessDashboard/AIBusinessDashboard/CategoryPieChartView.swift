//
//  CategoryPieChartView.swift
//  AIBusinessDashboard
//
//  Interactive pie chart for category revenue breakdown
//

import SwiftUI

// MARK: - Pie Chart View
struct CategoryPieChartView: View {
    let data: [PieChartData]
    @State private var selectedSlice: String? = nil
    @State private var animationProgress: Double = 0
    
    var body: some View {
        VStack {
            Text("Revenue by Category")
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack {
                    ForEach(data.indices, id: \.self) { index in
                        PieSlice(
                            startAngle: startAngle(for: index),
                            endAngle: endAngle(for: index),
                            color: sliceColor(for: index),
                            isSelected: selectedSlice == data[index].category,
                            animationProgress: animationProgress
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedSlice = selectedSlice == data[index].category ? nil : data[index].category
                            }
                        }
                    }
                    
                    // Center text
                    VStack {
                        if let selected = selectedSlice,
                           let item = data.first(where: { $0.category == selected }) {
                            Text(item.category)
                                .font(.headline)
                            Text("€\(Int(item.value).formatted())")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\(Int(item.percentage))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Total Revenue")
                                .font(.headline)
                            Text("€\(Int(totalValue).formatted())")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.width)
            }
            .aspectRatio(1, contentMode: .fit)
            .padding()
            
            // Legend
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(data.indices, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(sliceColor(for: index))
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading) {
                            Text(data[index].category)
                                .font(.caption)
                                .lineLimit(1)
                            Text("\(Int(data[index].percentage))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedSlice == data[index].category ? Color(.systemGray5) : Color.clear)
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedSlice = selectedSlice == data[index].category ? nil : data[index].category
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
    
    private var totalValue: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let sum = data.prefix(index).reduce(0) { $0 + $1.value }
        return Angle(degrees: (sum / totalValue) * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let sum = data.prefix(index + 1).reduce(0) { $0 + $1.value }
        return Angle(degrees: (sum / totalValue) * 360 - 90)
    }
    
    private func sliceColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .yellow, .pink, .mint]
        return colors[index % colors.count]
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let isSelected: Bool
    let animationProgress: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let selectedOffset: CGFloat = isSelected ? 20 : 0
            
            let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)
            let xOffset = selectedOffset * cos(midAngle.radians)
            let yOffset = selectedOffset * sin(midAngle.radians)
            
            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius * 0.9,
                    startAngle: startAngle,
                    endAngle: startAngle + (endAngle - startAngle) * animationProgress,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
            .overlay(
                Path { path in
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: radius * 0.9,
                        startAngle: startAngle,
                        endAngle: startAngle + (endAngle - startAngle) * animationProgress,
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .stroke(Color.white, lineWidth: 2)
            )
            .offset(x: xOffset, y: yOffset)
            .animation(.spring(), value: isSelected)
        }
    }
}
