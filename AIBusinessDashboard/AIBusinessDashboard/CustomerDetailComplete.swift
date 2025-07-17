//
//  CustomerDetailComplete.swift
//  AIBusinessDashboard
//
//  Extended customer detail views with advanced visualizations
//

import SwiftUI
import Charts
import MapKit

// MARK: - Extended Models

struct CustomerInteraction: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let type: InteractionType
    let details: String
    let channel: String
    let sentiment: Double? // -1 to 1
    
    enum InteractionType: String, Codable {
        case order = "order"
        case support = "support"
        case review = "review"
        case email = "email"
        case appVisit = "app_visit"
    }
}

struct CustomerPreferences: Codable {
    let favoriteCategories: [String]
    let preferredBrands: [String]
    let communicationPreference: String
    let marketingOptIn: Bool
    let avgSessionDuration: Int
    let deviceTypes: [String]
}

struct CustomerLifetimeStats: Codable {
    let firstOrderDate: Date
    let lastOrderDate: Date
    let totalDaysAsCustomer: Int
    let avgDaysBetweenOrders: Double
    let bestMonth: String
    let bestQuarter: String
    let seasonalityScore: Double
}

// MARK: - Customer Analytics View

struct CustomerAnalyticsView: View {
    let customerId: Int
    @StateObject private var viewModel = CustomerAnalyticsViewModel()
    @State private var selectedTimeRange = TimeRange.allTime
    @State private var showingPrediction = false
    
    enum TimeRange: String, CaseIterable {
        case month = "30D"
        case quarter = "90D"
        case year = "1Y"
        case allTime = "All"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Customer Score Card
                customerScoreCard
                
                // Time Range Selector
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Customer Value Chart
                customerValueChart
                
                // Interaction Timeline
                interactionTimeline
                
                // Behavioral Insights
                behavioralInsights
                
                // Predictive Analytics
                predictiveAnalytics
                
                // Customer Map (if addresses available)
                if let location = viewModel.customerLocation {
                    customerLocationMap(location: location)
                }
            }
        }
        .navigationTitle("Customer Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAnalytics(for: customerId)
        }
    }
    
    // MARK: - Customer Score Card
    private var customerScoreCard: some View {
        VStack(spacing: 20) {
            Text("Customer Health Score")
                .font(.headline)
            
            ZStack {
                // Background circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: CGFloat(200 - index * 40), height: CGFloat(200 - index * 40))
                }
                
                // Score circle
                Circle()
                    .trim(from: 0, to: viewModel.healthScore / 100)
                    .stroke(
                        AngularGradient(
                            colors: [.red, .orange, .yellow, .green],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 30, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: viewModel.healthScore)
                
                VStack {
                    Text("\(Int(viewModel.healthScore))")
                        .font(.system(size: 48, weight: .bold))
                    Text("Health Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Score breakdown
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ScoreComponent(
                    title: "Engagement",
                    score: viewModel.engagementScore,
                    icon: "person.2.fill"
                )
                
                ScoreComponent(
                    title: "Value",
                    score: viewModel.valueScore,
                    icon: "dollarsign.circle.fill"
                )
                
                ScoreComponent(
                    title: "Loyalty",
                    score: viewModel.loyaltyScore,
                    icon: "heart.fill"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Customer Value Chart
    private var customerValueChart: some View {
        VStack(alignment: .leading) {
            Text("Customer Lifetime Value Progression")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(viewModel.valueProgression) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("CLV", dataPoint.value)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("CLV", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                if dataPoint.isSignificant {
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("CLV", dataPoint.value)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(100)
                    .annotation(position: .top) {
                        Text(dataPoint.annotation ?? "")
                            .font(.caption2)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
            }
            .frame(height: 250)
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Interaction Timeline
    private var interactionTimeline: some View {
        VStack(alignment: .leading) {
            Text("Customer Journey")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(viewModel.interactions) { interaction in
                        InteractionNode(interaction: interaction)
                    }
                }
                .padding()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Behavioral Insights
    private var behavioralInsights: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Behavioral Insights")
                .font(.headline)
            
            // Purchase Patterns
            InsightCard(
                icon: "calendar.badge.clock",
                title: "Purchase Pattern",
                value: viewModel.purchasePattern,
                color: .purple
            )
            
            // Preferred Categories
            InsightCard(
                icon: "square.grid.2x2",
                title: "Top Categories",
                value: viewModel.topCategories.joined(separator: ", "),
                color: .orange
            )
            
            // Communication Preference
            InsightCard(
                icon: "envelope.badge",
                title: "Best Contact Time",
                value: viewModel.bestContactTime,
                color: .blue
            )
            
            // Device Usage
            InsightCard(
                icon: "iphone",
                title: "Device Preference",
                value: viewModel.devicePreference,
                color: .green
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
    
    // MARK: - Predictive Analytics
    private var predictiveAnalytics: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI Predictions")
                    .font(.headline)
                Spacer()
                
                Button(action: { showingPrediction.toggle() }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
            
            // Next Purchase Prediction
            PredictionCard(
                title: "Next Purchase",
                prediction: viewModel.nextPurchasePrediction,
                confidence: viewModel.predictionConfidence,
                icon: "cart.badge.plus"
            )
            
            // Churn Risk Analysis
            ChurnRiskGauge(
                risk: viewModel.churnRisk,
                factors: viewModel.churnFactors
            )
            
            // Recommendations
            VStack(alignment: .leading, spacing: 10) {
                Text("AI Recommendations")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(viewModel.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(recommendation)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
        .sheet(isPresented: $showingPrediction) {
            PredictionDetailView(customerId: customerId)
        }
    }
    
    // MARK: - Customer Location Map
    
    private func customerLocationMap(location: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading) {
            Text("Customer Location")
                .font(.headline)
                .padding(.horizontal)
            
            // FIX: Gebruik een wrapper voor Identifiable
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )), annotationItems: [LocationAnnotation(coordinate: location)]) { annotation in
                MapMarker(coordinate: annotation.coordinate, tint: .blue)
            }
            .frame(height: 200)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views

struct ScoreComponent: View {
    let title: String
    let score: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(scoreColor)
            
            Text("\(Int(score))%")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(scoreColor.opacity(0.1))
        )
    }
    
    var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

struct InteractionNode: View {
    let interaction: CustomerInteraction
    
    var body: some View {
        VStack {
            // Timeline line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 2)
            
            // Node
            VStack {
                ZStack {
                    Circle()
                        .fill(nodeColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: nodeIcon)
                        .foregroundColor(.white)
                }
                
                Text(interaction.type.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Text(interaction.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
    
    var nodeColor: Color {
        switch interaction.type {
        case .order: return .green
        case .support: return .orange
        case .review: return .purple
        case .email: return .blue
        case .appVisit: return .gray
        }
    }
    
    var nodeIcon: String {
        switch interaction.type {
        case .order: return "cart.fill"
        case .support: return "questionmark.bubble.fill"
        case .review: return "star.fill"
        case .email: return "envelope.fill"
        case .appVisit: return "iphone"
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct PredictionCard: View {
    let title: String
    let prediction: String
    let confidence: Double
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Text(prediction)
                .font(.headline)
            
            // Confidence bar
            HStack {
                Text("Confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: confidence)
                    .tint(.purple)
                
                Text("\(Int(confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
        )
    }
}

struct ChurnRiskGauge: View {
    let risk: Double
    let factors: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Churn Risk")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(riskLevel)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(riskColor.opacity(0.2))
                    )
                    .foregroundColor(riskColor)
            }
            
            // Risk meter
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(riskColor)
                        .frame(width: geometry.size.width * risk, height: 8)
                }
            }
            .frame(height: 8)
            
            // Top risk factors
            if !factors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Risk Factors:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(factors.prefix(3), id: \.self) { factor in
                        HStack {
                            Circle()
                                .fill(riskColor)
                                .frame(width: 4, height: 4)
                            Text(factor)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
        )
    }
    
    var riskLevel: String {
        if risk >= 0.8 { return "Critical" }
        if risk >= 0.6 { return "High" }
        if risk >= 0.4 { return "Medium" }
        return "Low"
    }
    
    var riskColor: Color {
        if risk >= 0.8 { return .red }
        if risk >= 0.6 { return .orange }
        if risk >= 0.4 { return .yellow }
        return .green
    }
}

// MARK: - View Models

@MainActor
class CustomerAnalyticsViewModel: ObservableObject {
    @Published var healthScore: Double = 0
    @Published var engagementScore: Double = 0
    @Published var valueScore: Double = 0
    @Published var loyaltyScore: Double = 0
    
    @Published var valueProgression: [CLVDataPoint] = []
    @Published var interactions: [CustomerInteraction] = []
    
    @Published var purchasePattern = "Weekly buyer"
    @Published var topCategories = ["Electronics", "Home & Garden"]
    @Published var bestContactTime = "Weekday evenings"
    @Published var devicePreference = "Mobile (iOS)"
    
    @Published var nextPurchasePrediction = "Within 7-10 days"
    @Published var predictionConfidence = 0.87
    @Published var churnRisk = 0.15
    @Published var churnFactors = ["Regular purchaser", "High engagement"]
    @Published var recommendations = [
        "Send personalized offer for Electronics category",
        "Invite to VIP loyalty program",
        "Schedule check-in call for next week"
    ]
    
    @Published var customerLocation: CLLocationCoordinate2D?
    
    func loadAnalytics(for customerId: Int) async {
        // Simulate loading with animations
        withAnimation(.easeInOut(duration: 1.0)) {
            healthScore = 85
            engagementScore = 92
            valueScore = 78
            loyaltyScore = 88
        }
        
        // Load value progression
        valueProgression = generateValueProgression()
        
        // Load interactions
        interactions = generateInteractions()
        
        // Set location (Amsterdam)
        customerLocation = CLLocationCoordinate2D(
            latitude: 52.3676,
            longitude: 4.9041
        )
    }
    
    private func generateValueProgression() -> [CLVDataPoint] {
        var dataPoints: [CLVDataPoint] = []
        let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        var cumulativeValue: Double = 0
        
        for month in 0..<24 {
            let date = Calendar.current.date(byAdding: .month, value: month, to: startDate)!
            let monthlySpend = Double.random(in: 200...800)
            cumulativeValue += monthlySpend
            
            let isSignificant = month == 6 || month == 12 || month == 18
            let annotation = isSignificant ? "Milestone" : nil
            
            dataPoints.append(CLVDataPoint(
                date: date,
                value: cumulativeValue,
                isSignificant: isSignificant,
                annotation: annotation
            ))
        }
        
        return dataPoints
    }
    
    private func generateInteractions() -> [CustomerInteraction] {
        var interactions: [CustomerInteraction] = []
        let types: [CustomerInteraction.InteractionType] = [.order, .support, .review, .email, .appVisit]
        
        for i in 0..<10 {
            let daysAgo = i * 15
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            
            interactions.append(CustomerInteraction(
                id: UUID().uuidString,
                timestamp: date,
                type: types.randomElement()!,
                details: "Interaction details",
                channel: ["app", "email", "phone", "web"].randomElement()!,
                sentiment: Double.random(in: -1...1)
            ))
        }
        
        return interactions.sorted { $0.timestamp < $1.timestamp }
    }
}

struct CLVDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let isSignificant: Bool
    let annotation: String?
}

// MARK: - Prediction Detail View

struct PredictionDetailView: View {
    let customerId: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Model Information
                    modelInfoSection
                    
                    // Feature Importance
                    featureImportanceChart
                    
                    // Prediction Timeline
                    predictionTimeline
                    
                    // Confidence Breakdown
                    confidenceBreakdown
                }
                .padding()
            }
            .navigationTitle("AI Prediction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var modelInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Model Information", systemImage: "cpu")
                .font(.headline)
            
            InfoRow(label: "Algorithm", value: "XGBoost Classifier")
            InfoRow(label: "Accuracy", value: "94.2%")
            InfoRow(label: "Last Trained", value: "2 days ago")
            InfoRow(label: "Features Used", value: "47")
            InfoRow(label: "Training Samples", value: "125,000+")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var featureImportanceChart: some View {
        VStack(alignment: .leading) {
            Text("Top Prediction Factors")
                .font(.headline)
            
            Chart([
                ("Purchase Frequency", 0.28),
                ("Days Since Last Order", 0.22),
                ("Average Order Value", 0.18),
                ("Category Diversity", 0.15),
                ("Customer Tenure", 0.12),
                ("Support Interactions", 0.05)
            ], id: \.0) { feature, importance in
                BarMark(
                    x: .value("Importance", importance),
                    y: .value("Feature", feature)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var predictionTimeline: some View {
        VStack(alignment: .leading) {
            Text("Prediction Timeline")
                .font(.headline)
            
            ForEach(0..<4) { week in
                HStack {
                    Circle()
                        .fill(week == 1 ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading) {
                        Text("Week \(week + 1)")
                            .font(.subheadline)
                            .fontWeight(week == 1 ? .bold : .regular)
                        
                        Text(week == 1 ? "87% purchase probability" : "\(87 - week * 15)% probability")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if week == 1 {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.purple)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var confidenceBreakdown: some View {
        VStack(alignment: .leading) {
            Text("Confidence Analysis")
                .font(.headline)
            
            VStack(spacing: 10) {
                ConfidenceRow(
                    factor: "Historical Pattern Match",
                    confidence: 0.92,
                    impact: .positive
                )
                
                ConfidenceRow(
                    factor: "Seasonal Alignment",
                    confidence: 0.85,
                    impact: .positive
                )
                
                ConfidenceRow(
                    factor: "Recent Engagement",
                    confidence: 0.78,
                    impact: .neutral
                )
                
                ConfidenceRow(
                    factor: "Price Sensitivity",
                    confidence: 0.45,
                    impact: .negative
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct ConfidenceRow: View {
    let factor: String
    let confidence: Double
    let impact: Impact
    
    enum Impact {
        case positive, neutral, negative
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .neutral: return .orange
            case .negative: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "arrow.up.circle.fill"
            case .neutral: return "minus.circle.fill"
            case .negative: return "arrow.down.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: impact.icon)
                .foregroundColor(impact.color)
            
            VStack(alignment: .leading) {
                Text(factor)
                    .font(.subheadline)
                
                ProgressView(value: confidence)
                    .tint(impact.color)
            }
            
            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Customer Communication View

struct CustomerCommunicationView: View {
    let customerId: Int
    @State private var selectedChannel = CommunicationChannel.all
    @State private var showingComposeView = false
    
    enum CommunicationChannel: String, CaseIterable {
        case all = "All"
        case email = "Email"
        case sms = "SMS"
        case push = "Push"
        case inApp = "In-App"
    }
    
    var body: some View {
        VStack {
            // Channel Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(CommunicationChannel.allCases, id: \.self) { channel in
                        ChannelChip(
                            channel: channel,
                            isSelected: selectedChannel == channel,
                            action: { selectedChannel = channel }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Communication History
            List {
                ForEach(0..<10) { index in
                    CommunicationRow(
                        date: Date().addingTimeInterval(-Double(index * 86400)),
                        channel: CommunicationChannel.allCases.randomElement()!,
                        subject: "Communication #\(index)",
                        status: ["Sent", "Opened", "Clicked"].randomElement()!
                    )
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Communications")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingComposeView = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingComposeView) {
            ComposeMessageView(customerId: customerId)
        }
    }
}

struct ChannelChip: View {
    let channel: CustomerCommunicationView.CommunicationChannel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: channelIcon)
                Text(channel.rawValue)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
    
    var channelIcon: String {
        switch channel {
        case .all: return "tray.2"
        case .email: return "envelope"
        case .sms: return "message"
        case .push: return "bell"
        case .inApp: return "app.badge"
        }
    }
}

struct CommunicationRow: View {
    let date: Date
    let channel: CustomerCommunicationView.CommunicationChannel
    let subject: String
    let status: String
    
    var body: some View {
        HStack {
            Image(systemName: channelIcon)
                .foregroundColor(channelColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subject)
                    .font(.subheadline)
                    .lineLimit(1)
                
                HStack {
                    Text(date, style: .date)
                    Text("•")
                    Text(status)
                        .foregroundColor(statusColor)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    var channelIcon: String {
        switch channel {
        case .all: return "tray.2"
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .push: return "bell.fill"
        case .inApp: return "app.badge.fill"
        }
    }
    
    var channelColor: Color {
        switch channel {
        case .all: return .gray
        case .email: return .blue
        case .sms: return .green
        case .push: return .orange
        case .inApp: return .purple
        }
    }
    
    var statusColor: Color {
        switch status {
        case "Clicked": return .green
        case "Opened": return .blue
        default: return .secondary
        }
    }
}

struct ComposeMessageView: View {
    let customerId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedChannel = CustomerCommunicationView.CommunicationChannel.email
    @State private var subject = ""
    @State private var message = ""
    @State private var useTemplate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Channel") {
                    Picker("Channel", selection: $selectedChannel) {
                        ForEach(CustomerCommunicationView.CommunicationChannel.allCases.filter { $0 != .all }, id: \.self) { channel in
                            Label(channel.rawValue, systemImage: channelIcon(for: channel))
                                .tag(channel)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Message") {
                    if selectedChannel == .email {
                        TextField("Subject", text: $subject)
                    }
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }
                
                Section("Options") {
                    Toggle("Use Template", isOn: $useTemplate)
                    
                    if useTemplate {
                        Picker("Template", selection: .constant("welcome")) {
                            Text("Welcome Message").tag("welcome")
                            Text("Win-back Campaign").tag("winback")
                            Text("VIP Invitation").tag("vip")
                        }
                    }
                }
                
                Section {
                    Button(action: sendMessage) {
                        Label("Send Message", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func channelIcon(for channel: CustomerCommunicationView.CommunicationChannel) -> String {
        switch channel {
        case .all: return "tray.2"
        case .email: return "envelope"
        case .sms: return "message"
        case .push: return "bell"
        case .inApp: return "app.badge"
        }
    }
    
    private func sendMessage() {
        // Send message logic
        dismiss()
    }
}

// MARK: - Location Helper
struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
