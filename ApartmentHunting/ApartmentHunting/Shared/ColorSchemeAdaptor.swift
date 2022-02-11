//
//  ColorSchemeAdaptor.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/11/22.
//

import SwiftUI

enum ColorSchemeAdaptor: Int {
    case automatic = 0, light, dark
}

extension ColorScheme {
    init?(adaptor: ColorSchemeAdaptor) {
        switch adaptor {
        case .automatic:
            return nil
        case .light:
            self = .light
        case .dark:
            self = .dark
        }
    }
}
