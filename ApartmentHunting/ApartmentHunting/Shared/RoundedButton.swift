//
//  RoundedButton.swift
//  Apartments
//
//  Created by Jack Rosen on 1/22/22.
//

import SwiftUI

struct RoundedButtonStyle: ButtonStyle {
    let color: Color
    let enabled: Bool
    
    @ViewBuilder
    private func backgroundView(configuration: Configuration) -> some View {
        if configuration.isPressed {
            color.cornerRadius(10)
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).stroke())
            .foregroundColor(enabled ? color : .gray)
            .background(backgroundView(configuration: configuration))
            .multilineTextAlignment(.center)
            .opacity(!enabled ? 0.5 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityHidden(!enabled)
        #if os(iOS)
            .hoverEffect(.highlight)
        #endif
    }
}

struct RoundedButton: View {
    @Environment(\.isEnabled) var enabled
    let title: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
        }.buttonStyle(RoundedButtonStyle(color: color, enabled: enabled))
    }
}
