//
//  Initializer.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

class Initializer: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    override init() {
        super.init()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        Task {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert])
            await UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            return
        }
        print(fcmToken)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print(notification)
        completionHandler([.badge, .sound, .banner])
    }
}
