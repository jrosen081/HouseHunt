//
//  ApartmentHuntingApp.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import SwiftUI
#if !os(macOS)
import UIKit
#else
import AppKit
#endif

import FirebaseMessaging
import UserNotifications
import Firebase

@main
struct ApartmentHuntingApp: App {
    #if !os(macOS)
    @UIApplicationDelegateAdaptor(UIAppDelegate.self) var delegate
    #else
    @NSApplicationDelegateAdaptor(NSAppDelegate.self) var delegate
    #endif
    @StateObject var initializer = Initializer()
    @StateObject var authInteractor = AuthInteractor()
    @StateObject var linkInteractor = LinkInteractor()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(linkInteractor)
                .environmentObject(authInteractor)
                .environmentObject(initializer)
                .preferredColorScheme(ColorScheme(adaptor: initializer.userInterfaceStyle))
                .menuStyle(.borderlessButton)
                .onAppear {
                    #if os(macOS)
                    NSWindow.allowsAutomaticWindowTabbing = false
                    #endif
                }
        }.commands {
            SidebarCommands()
        }
    }
}
