//
//  NotificationManager.swift
//  AIBusinessDashboard
//
//  Created by Daan van der Ster on 17/07/2025.
//

import Foundation
import UserNotifications
import SwiftUI

@MainActor
class NotificationManager: NSObject, ObservableObject {
    @Published var hasPermission = false
    @Published var pendingRequests: [UNNotificationRequest] = []
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermissionStatus()
    }
    
    // MARK: - Permission Management
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            hasPermission = granted
            
            if granted {
                print("✅ Push notification permission granted")
                await scheduleInitialNotifications()
            } else {
                print("❌ Push notification permission denied")
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    private func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleInitialNotifications() async {
        // Clear existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule different types of notifications
        await scheduleRevenueAlerts()
        await scheduleChurnAlerts()
        await scheduleDailySummary()
        await scheduleMotivationalAlerts()
        
        // Update pending requests
        await updatePendingRequests()
    }
    
    // MARK: - Revenue Alerts
    private func scheduleRevenueAlerts() async {
        // High revenue day alert
        let revenueContent = UNMutableNotificationContent()
        revenueContent.title = "🚀 Exceptional Performance!"
        revenueContent.body = "Daily revenue target exceeded: €42,567! Keep up the momentum."
        revenueContent.sound = .default
        revenueContent.badge = 1
        revenueContent.categoryIdentifier = "REVENUE_ALERT"
        
        // Trigger in 10 seconds for demo
        let revenueTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let revenueRequest = UNNotificationRequest(
            identifier: "high_revenue_\(Date().timeIntervalSince1970)",
            content: revenueContent,
            trigger: revenueTrigger
        )
        
        try? await UNUserNotificationCenter.current().add(revenueRequest)
        
        // Weekly milestone alert
        let weeklyContent = UNMutableNotificationContent()
        weeklyContent.title = "📊 Weekly Milestone"
        weeklyContent.body = "Best week this month! €284K total revenue across 7 days."
        weeklyContent.sound = .default
        weeklyContent.categoryIdentifier = "MILESTONE_ALERT"
        
        let weeklyTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 25, repeats: false)
        let weeklyRequest = UNNotificationRequest(
            identifier: "weekly_milestone_\(Date().timeIntervalSince1970)",
            content: weeklyContent,
            trigger: weeklyTrigger
        )
        
        try? await UNUserNotificationCenter.current().add(weeklyRequest)
    }
    
    // MARK: - Churn Risk Alerts
    private func scheduleChurnAlerts() async {
        let churnContent = UNMutableNotificationContent()
        churnContent.title = "⚠️ Customer Alert"
        churnContent.body = "3 platinum customers show high churn risk. Review recommended actions."
        churnContent.sound = UNNotificationSound(named: UNNotificationSoundName("alert_sound.caf"))
        churnContent.badge = 2
        churnContent.categoryIdentifier = "CHURN_ALERT"
        
        // Add action buttons
        let viewAction = UNNotificationAction(
            identifier: "VIEW_CUSTOMERS",
            title: "View Details",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )
        
        let churnCategory = UNNotificationCategory(
            identifier: "CHURN_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([churnCategory])
        
        let churnTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 40, repeats: false)
        let churnRequest = UNNotificationRequest(
            identifier: "churn_risk_\(Date().timeIntervalSince1970)",
            content: churnContent,
            trigger: churnTrigger
        )
        
        try? await UNUserNotificationCenter.current().add(churnRequest)
    }
    
    // MARK: - Daily Summary
    private func scheduleDailySummary() async {
        let summaryContent = UNMutableNotificationContent()
        summaryContent.title = "📈 Daily Business Summary"
        summaryContent.body = "Today: 22 orders • €42,567 revenue • 98.2% ML accuracy"
        summaryContent.sound = .default
        summaryContent.badge = 3
        summaryContent.categoryIdentifier = "DAILY_SUMMARY"
        
        // Schedule for every day at 6 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let dailyTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let summaryRequest = UNNotificationRequest(
            identifier: "daily_summary",
            content: summaryContent,
            trigger: dailyTrigger
        )
        
        try? await UNUserNotificationCenter.current().add(summaryRequest)
    }
    
    // MARK: - Motivational Alerts
    private func scheduleMotivationalAlerts() async {
        let motivationContent = UNMutableNotificationContent()
        motivationContent.title = "💪 Team Performance"
        motivationContent.body = "Customer satisfaction up 15% this month. Your analytics are driving results!"
        motivationContent.sound = .default
        motivationContent.categoryIdentifier = "MOTIVATION"
        
        let motivationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let motivationRequest = UNNotificationRequest(
            identifier: "motivation_\(Date().timeIntervalSince1970)",
            content: motivationContent,
            trigger: motivationTrigger
        )
        
        try? await UNUserNotificationCenter.current().add(motivationRequest)
    }
    
    // MARK: - Manual Notifications
    func sendInstantAlert(title: String, body: String, category: String = "INSTANT") async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.categoryIdentifier = category
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "instant_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Utility Functions
    private func updatePendingRequests() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingRequests = requests
        print("📱 Scheduled \(requests.count) notifications")
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        pendingRequests = []
    }
    
    func getBadgeCount() -> Int {
        return UIApplication.shared.applicationIconBadgeNumber
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is active
        completionHandler([.alert, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        print("📱 Notification tapped: \(categoryIdentifier), action: \(actionIdentifier)")
        
        // Handle different actions
        switch actionIdentifier {
        case "VIEW_CUSTOMERS":
            // Navigate to customers view
            print("Navigate to customers view")
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification (default action)
            print("Default notification tap")
        default:
            break
        }
        
        completionHandler()
    }
}
