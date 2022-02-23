//
//  Searchable.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import SwiftUI

extension View {
    @ViewBuilder
    func back_searchable(text: Binding<String>, prompt: String) -> some View {
        if #available(iOS 15, macOS 12, *) {
            Group {
                if #available(iOS 15, macOS 12, *) {
                    self.searchable(text: text, prompt: prompt)
                }
            }
            
        } else {
            self
        }
    }
}
