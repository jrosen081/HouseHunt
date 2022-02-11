//
//  ApartmentHuntingApp.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import SwiftUI
import UIKit
import FirebaseMessaging
import UserNotifications
import Firebase

@main
struct ApartmentHuntingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authInteractor = AuthInteractor()
    @StateObject var initializer = Initializer()
    @StateObject var linkInteractor = LinkInteractor()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationViewStyle(.stack)
                .environmentObject(linkInteractor)
                .environmentObject(authInteractor)
                .environmentObject(initializer)
                .preferredColorScheme(ColorScheme(initializer.userInterfaceStyle))
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
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
