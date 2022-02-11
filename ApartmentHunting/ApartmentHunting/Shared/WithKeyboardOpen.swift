//
//  WithKeyboardOpen.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/10/22.
//

import Combine
import SwiftUI

@propertyWrapper
struct KeyboardOpenState: DynamicProperty {
    private class KeyboardOpenListener: ObservableObject {
        static let shared = KeyboardOpenListener()
        var anyCancellables: Set<AnyCancellable> = []
        private init() {
            #if !os(macOS)
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification, object: nil)
                .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification, object: nil))
                .sink { notification in
                    self.isKeyboardOpen = notification.name == UIResponder.keyboardWillShowNotification
                }.store(in: &anyCancellables)
            #endif
        }
        @Published var isKeyboardOpen = false
    }
    @ObservedObject private var listener = KeyboardOpenListener.shared
    
    
    var wrappedValue: Bool {
        return listener.isKeyboardOpen
    }
}
