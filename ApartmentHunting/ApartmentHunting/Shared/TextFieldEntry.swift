//
//  TextFieldEntry.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/4/22.
//

import SwiftUI

struct TextFieldEntry: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    @Environment(\.isEnabled) var enabled
    @Environment(\.sizeCategory) var size
    
    private var fontSize: Font {
        size > .medium ? Font.subheadline : Font.headline
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .bold()
                .accessibilityHidden(true)
                .opacity(enabled ? 1 : 0.2)
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .padding(5)
            .padding(.horizontal, 5)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke().opacity(enabled ? 1 : 0.2))
            .textFieldStyle(.plain)
        }
        .multilineTextAlignment(.leading)
        .font(fontSize)
    }
}
