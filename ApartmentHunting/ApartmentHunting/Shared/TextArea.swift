//
//  TextArea.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/4/22.
//

import SwiftUI

struct TextArea: View {
    let title: String
    @Binding var text: String
    var body: some View {
        Text(title)
            .font(.subheadline)
            .bold()
        TextEditor(text: $text)
            .padding(5)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke())
            .frame(minHeight: 50, maxHeight: 350)
    }
}
