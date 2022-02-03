//
//  ContentView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authInteractor: AuthInteractor
    var body: some View {
        switch authInteractor.authState {
        case .success(_):
            UserOptionsView()
        default:
            SignInView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
