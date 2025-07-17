import SwiftUI

struct CustomerListView: View {
    @StateObject private var viewModel = CustomerListViewModel()
    @State private var searchText = ""
    @State private var selectedTier = "All"
    @State private var sortBy = SortOption.value
    
    enum SortOption: String, CaseIterable {
        case value = "Value"
        case orders = "Orders"
        case recent = "Recent"
        case risk = "Risk"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search customers...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        FilterChip(
                            title: "All Tiers",
                            isSelected: selectedTier == "All",
                            action: { selectedTier = "All" }
                        )
                        
                        ForEach(["Platinum", "Gold", "Silver", "Bronze"], id: \.self) { tier in
                            FilterChip(
                                title: tier,
                                isSelected: selectedTier == tier,
                                action: { selectedTier = tier }
                            )
                        }
                        
                        Spacer()
                        
                        // Sort picker
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: { sortBy = option }) {
                                    HStack {
                                        Text("Sort by \(option.rawValue)")
                                        if sortBy == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(sortBy.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Customer list
            List {
                ForEach(filteredCustomers) { customer in
                    NavigationLink {
                        CustomerAnalyticsView(customerId: customer.id)
                    } label: {
                        CustomerRow(customer: customer)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                await viewModel.loadCustomers()
            }
        }
        .navigationTitle("Customers")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadCustomers()
        }
    }
    
    var filteredCustomers: [CustomerSummary] {
        var customers = viewModel.customers
        
        // Filter by search
        if !searchText.isEmpty {
            customers = customers.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by tier
        if selectedTier != "All" {
            customers = customers.filter { $0.tier == selectedTier }
        }
        
        // Sort
        switch sortBy {
        case .value:
            customers.sort { $0.totalValue > $1.totalValue }
        case .orders:
            customers.sort { $0.orderCount > $1.orderCount }
        case .recent:
            customers.sort { $0.lastOrderDate > $1.lastOrderDate }
        case .risk:
            customers.sort { $0.churnRisk > $1.churnRisk }
        }
        
        return customers
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct CustomerRow: View {
    let customer: CustomerSummary
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            CustomerAvatar(name: customer.name, tier: customer.tier)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(customer.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    TierBadge(tier: customer.tier)
                    
                    Spacer()
                    
                    Text("€\(Int(customer.totalValue).formatted())")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(customer.orderCount) orders")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    ChurnRiskIndicator(risk: customer.churnRisk)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CustomerAvatar: View {
    let name: String
    let tier: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(tierColor.opacity(0.2))
                .frame(width: 50, height: 50)
            
            Text(String(name.prefix(1)))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(tierColor)
        }
    }
    
    var tierColor: Color {
        switch tier {
        case "Platinum": return .purple
        case "Gold": return .orange
        case "Silver": return .gray
        default: return .blue
        }
    }
}

struct TierBadge: View {
    let tier: String
    
    var body: some View {
        Text(tier)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(tierColor.opacity(0.2))
            )
            .foregroundColor(tierColor)
    }
    
    var tierColor: Color {
        switch tier {
        case "Platinum": return .purple
        case "Gold": return .orange
        case "Silver": return .gray
        default: return .blue
        }
    }
}

struct ChurnRiskIndicator: View {
    let risk: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(riskColor)
                .frame(width: 6, height: 6)
            
            Text(riskLevel)
                .font(.caption2)
                .foregroundColor(riskColor)
        }
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

// View Model
@MainActor
class CustomerListViewModel: ObservableObject {
    @Published var customers: [CustomerSummary] = []
    @Published var isLoading = false
    
    func loadCustomers() async {
        isLoading = true
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        customers = generateMockCustomers()
        isLoading = false
    }
    
    private func generateMockCustomers() -> [CustomerSummary] {
        let names = [
            "Sarah Johnson", "Mike Chen", "Emma Williams", "James Rodriguez",
            "Lisa Anderson", "David Kim", "Maria Garcia", "Robert Taylor",
            "Jennifer Martinez", "Christopher Lee", "Amanda Thompson", "Kevin Zhang"
        ]
        
        let tiers = ["Platinum", "Gold", "Silver", "Bronze"]
        
        return names.enumerated().map { index, name in
            CustomerSummary(
                id: 100 + index,
                name: name,
                tier: tiers[index % tiers.count],
                totalValue: Double.random(in: 1000...20000),
                orderCount: Int.random(in: 5...50),
                churnRisk: Double.random(in: 0...1),
                lastOrderDate: Date().addingTimeInterval(-Double.random(in: 0...86400*30))
            )
        }
    }
}

struct CustomerSummary: Identifiable {
    let id: Int
    let name: String
    let tier: String
    let totalValue: Double
    let orderCount: Int
    let churnRisk: Double
    let lastOrderDate: Date
}

// Helper for info rows in prediction detail
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationView {
        CustomerListView()
    }
}
