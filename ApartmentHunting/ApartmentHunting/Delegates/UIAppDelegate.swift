//
//  UIAppDelegate.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/11/22.
//

import Firebase
import FirebaseMessaging
import UIKit

class UIAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Task {
            UNUserNotificationCenter.current().delegate = self
            let _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert])
            UIApplication.shared.registerForRemoteNotifications()
        }
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.sound, .badge, .banner]
    }
}
