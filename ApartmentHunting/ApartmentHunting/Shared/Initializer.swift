//
//  Initializer.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import Firebase
import FirebaseMessaging
import UserNotifications

class Initializer: NSObject, ObservableObject, MessagingDelegate {
    struct EventResponderHolder {
        weak var responder: EventResponder?
    }
    private enum Constants {
        static let userStyleKey = "userStyle"
    }
    
    @Published var userInterfaceStyle: ColorSchemeAdaptor = ColorSchemeAdaptor(rawValue: UserDefaults.standard.integer(forKey: Constants.userStyleKey)) ?? .automatic {
        didSet {
            UserDefaults.standard.set(userInterfaceStyle.rawValue, forKey: Constants.userStyleKey)
        }
    }
    
    @Published var eventResponders: [EventResponderHolder] = []
    
    override init() {
        super.init()
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            return
        }
        print(fcmToken)
    }
}

