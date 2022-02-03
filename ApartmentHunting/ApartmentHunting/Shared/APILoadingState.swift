//
//  LoadingState.swift
//  JexiApp
//
//  Created by Jack Rosen on 1/10/22.
//

import Foundation

enum LoadingState<T: Equatable>: Equatable {
    case notStarted, loading, success(T), error(String)
}
