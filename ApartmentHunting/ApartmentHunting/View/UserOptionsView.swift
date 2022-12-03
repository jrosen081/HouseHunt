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
    @State private var showingProfile = false
    var body: some View {
        VStack {
            HStack {
                #if os(macOS)
                if showingProfile {
                    Text(L10n.WaitingView.profile).font(.largeTitle).bold()
                }
                #endif
                Spacer()
                Button {
                    self.showingProfile.toggle()
                } label: {
                    #if os(iOS)
                    Label(L10n.showProfile, systemImage: "person.circle").labelStyle(.iconOnly)
                        .foregroundColor(.primary)
                    #else
                    if showingProfile {
                        Text(L10n.dismiss)
                    } else {
                        Label(L10n.showProfile, systemImage: "person.circle").labelStyle(.iconOnly)
                    }
                    #endif
                }
            }
            ZStack {
                VStack(alignment: .leading) {
                    Text(L10n.WaitingView.waitingOnResponse).font(.largeTitle).bold()
                        .padding(.bottom)
                    HStack {
                        Text(L10n.WaitingView.searchName).bold()
                        Text(name)
                    }.font(.title)
                    
                    Spacer()
                    RoundedButton(title: L10n.WaitingView.removeRequestButton, color: .red) {
                        Task {
                            try? await ApartmentAPIInteractor.removeApartmentRequest(id: id, currentUser: user, authInteractor: authInteractor)
                        }
                    }
                }
#if os(iOS)
                .sheet(isPresented: $showingProfile) {
                    NavigationView {
                        ProfileView()
                    }
                }
#endif
                #if os(macOS)
                if self.showingProfile {
                    ProfileView()
                        .animation(.linear, value: showingProfile)
                }
                #endif
            }
        }.padding()
        
    }
}
