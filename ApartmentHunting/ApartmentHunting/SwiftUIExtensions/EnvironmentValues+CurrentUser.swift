//
//  EnvironmentValues+CurrentUser.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/28/22.
//

import SwiftUI

@propertyWrapper
struct CurrentUserState: DynamicProperty {
    @EnvironmentObject var authInteractor: AuthInteractor
    
    var wrappedValue: User {
        switch authInteractor.authState {
        case .success(let user): return user
        default: return User(id: nil, apartmentSearchState: .noRequest, name: "")
        }
    }
}
