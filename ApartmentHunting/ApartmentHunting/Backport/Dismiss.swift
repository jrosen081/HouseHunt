//
//  Dismiss.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import Foundation
import SwiftUI

extension EnvironmentValues {
    var back_dismiss: () -> Void {
        #if os(iOS)
        if #available(iOS 15, macOS 12, *) {
            return { dismiss() }
        } else {
            return { presentationMode.wrappedValue.dismiss() }
        }
        #else
        return {}
        #endif
    }
}
