//
//  DismissKeyboardOnTap.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/10/22.
//

import SwiftUI

extension View {
    func removingKeyboardOnTap() -> some View {
        ZStack {
            #if !os(macOS)
            Button(action: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }) {
                Color.clear
            }
            #endif
            self
        }
    }
}
