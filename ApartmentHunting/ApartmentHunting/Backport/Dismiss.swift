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
        if #available(iOS 15, *) {
            return { dismiss() }
        } else {
            return { presentationMode.wrappedValue.dismiss() }
        }
    }
}
