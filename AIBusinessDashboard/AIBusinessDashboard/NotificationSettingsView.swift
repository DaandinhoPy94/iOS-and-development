//
//  NotificationSettingsView.swift
//  AIBusinessDashboard
//
//  Created by Daan van der Ster on 17/07/2025.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Permission Status Section
                Section {
                    HStack {
                        Image(systemName: notificationManager.hasPermission ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(notificationManager.hasPermission ? .green : .red)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Push Notifications")
                                .font(.headline)
                            Text(notificationManager.hasPermission ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !notificationManager.hasPermission {
                            Button("Enable") {
                                Task {
                                    await notificationManager.requestPermission()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Text("Status")
                } footer: {
                    Text("Enable notifications to receive real-time business alerts and daily summaries.")
                }
                
                // Quick Actions Section
                if notificationManager.hasPermission {
                    Section("Test Notifications") {
                        Button {
                            Task {
                                await notificationManager.sendInstantAlert(
                                    title: "🎉 Test Alert",
                                    body: "Notifications are working perfectly! You'll receive business updates here."
                                )
                            }
                        } label: {
                            Label("Send Test Notification", systemImage: "bell.badge")
                        }
                        
                        Button {
                            Task {
                                await notificationManager.sendInstantAlert(
                                    title: "💰 Revenue Update",
                                    body: "Great day! Current revenue: €45,234 (+23% vs yesterday)"
                                )
                            }
                        } label: {
                            Label("Test Revenue Alert", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        
                        Button {
                            Task {
                                await notificationManager.sendInstantAlert(
                                    title: "⚠️ Customer Alert",
                                    body: "2 platinum customers need attention. Churn risk detected."
                                )
                            }
                        } label: {
                            Label("Test Churn Alert", systemImage: "person.crop.circle.badge.exclamationmark")
                        }
                    }
                    
                    // Schedule Management
                    Section("Scheduled Notifications") {
                        Button {
                            Task {
                                await notificationManager.scheduleInitialNotifications()
                            }
                        } label: {
                            Label("Schedule Demo Notifications", systemImage: "calendar.badge.plus")
                        }
                        
                        Text("Pending: \(notificationManager.pendingRequests.count) notifications")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Management Section
                    Section("Management") {
                        Button(role: .destructive) {
                            notificationManager.clearAllNotifications()
                        } label: {
                            Label("Clear All Notifications", systemImage: "trash")
                        }
                    }
                }
                
                // Information Section
                Section("Notification Types") {
                    Label("Revenue milestones and targets", systemImage: "dollarsign.circle")
                    Label("Customer churn risk alerts", systemImage: "person.crop.circle.badge.exclamationmark")
                    Label("Daily performance summaries", systemImage: "chart.bar")
                    Label("Weekly business insights", systemImage: "calendar")
                }
                
                // Badge Count Info
                if notificationManager.hasPermission {
                    Section("App Badge") {
                        HStack {
                            Text("Current Badge Count")
                            Spacer()
                            Text("\(notificationManager.getBadgeCount())")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive business alerts.")
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
