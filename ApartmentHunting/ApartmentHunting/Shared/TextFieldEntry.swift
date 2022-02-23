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
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .bold()
                .accessibilityHidden(true)
            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .padding(5)
            .padding(.horizontal, 5)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke())
            .textFieldStyle(.plain)
        }.multilineTextAlignment(.leading)
        
    }
}
