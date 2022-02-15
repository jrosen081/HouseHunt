//
//  UserOptionsView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/30/22.
//

import SwiftUI
import FirebaseMessaging

struct UserOptionsView: View {
    @CurrentUserState var user: User
    @EnvironmentObject var authInteractor: AuthInteractor
    var body: some View {
        switch user.apartmentSearchState {
        case .success(let id):
            LoadApartmentView(id: id)
        case .noRequest:
            NavigationView {
                ApartmentRequestView()
            }
        case .requested(let name, let id):
            WaitingView(name: name, id: id)
            
        }
    }
}

private struct WaitingView: View {
    let name: String
    let id: String
    @EnvironmentObject var authInteractor: AuthInteractor
    @CurrentUserState var user
    var body: some View {
        VStack(alignment: .leading) {
            Text("Waiting on Response").font(.largeTitle).bold()
                .padding(.bottom)
            HStack {
                Text("Search Name:").bold()
                Text(name)
            }.font(.title)
            
            Spacer()
            RoundedButton(title: "Remove Request", color: .red) {
                Task {
                    try? await ApartmentAPIInteractor.removeApartmentRequest(id: id, currentUser: user, authInteractor: authInteractor)
                }
            }
            RoundedButton(title: "Sign Out", color: .red) {
                authInteractor.signOut()
            }
        }.padding()
    }
}
