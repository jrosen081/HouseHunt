//
//  Image.swift
//  HomeHunt
//
//  Created by Jack Rosen on 2/22/22.
//

import SwiftUI

extension Image {
    public static let filter: String = {
        if #available(iOS 15, macOS 12, *) {
            return "line.3.horizontal.decrease.circle"
        } else {
            return "line.horizontal.3.decrease.circle"
        }
    }()
}
