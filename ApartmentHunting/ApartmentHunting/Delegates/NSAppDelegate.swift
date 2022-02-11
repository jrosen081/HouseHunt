//
//  NSAppDelegate.swift
//  Home Hunt
//
//  Created by Jack Rosen on 2/11/22.
//

import Foundation
import AppKit
import Firebase

class NSAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Task {
            UNUserNotificationCenter.current().delegate = self
            let _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert])
            await NSApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    @objc(userNotificationCenter:willPresentNotification:withCompletionHandler:) func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.sound, .badge, .banner]
    }
}
