//
//  SearchView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/30/22.
//

import SwiftUI

struct SearchView: View {
    @CurrentUserState var user
    @EnvironmentObject var apartmentSearch: ApartmentSearch
    @EnvironmentObject var authInteractor: AuthInteractor
    @State private var message: String? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                if !apartmentSearch.requests.isEmpty {
                    Section(header: Text("Join Requests")) {
                        ForEach(apartmentSearch.requests) { user in
                            AcceptRejectView(user: user)
                        }
                    }
                }
                Section(header: Text("Home Info")) {
                    HStack {
                        Text("Name:")
                        Spacer()
                        Text(apartmentSearch.name)
                    }
                    Button(action: {
                        UIPasteboard.general.string = apartmentSearch.entryCode
                        withAnimation { self.message = "Code Copied" }
                    }) {
                        HStack {
                            Text("Join Code:")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(apartmentSearch.entryCode)
                                .foregroundColor(.blue)
                        }
                    }
                }
                Section(header: Text("Danger Zone")) {
                    Button("Leave Home Search") {
                        ApartmentAPIInteractor.rejectUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
                    }.foregroundColor(.red)
                    Button("Sign Out") {
                        authInteractor.signOut()
                    }.foregroundColor(.red)
                }
            }.navigationTitle("Settings")
                .listStyle(.insetGrouped)
            if let message = message {
                Text(message)
                    .padding()
                    .background(Capsule().fill(.green))
                    .transition(.move(edge: .bottom))
                    .foregroundColor(.white)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                self.message = nil
                            }
                        }
                    }
            }
        }
    }
}

private struct AcceptRejectView: View {
    let user: User
    @EnvironmentObject var authInteractor: AuthInteractor
    @State private var administering = false
    @EnvironmentObject var apartmentSearch: ApartmentSearch
    
    var body: some View {
        HStack {
            Text(user.name)
            Spacer()
            Button(action: {
                self.administering = true
            }) {
                Text("Manage")
            }.actionSheet(isPresented: $administering) {
                ActionSheet(title: Text("Manage User"), message: nil, buttons: [
                    .default(Text("Accept"), action: {
                        ApartmentAPIInteractor.acceptUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
                    }),
                    .destructive(Text("Reject")) {
                        ApartmentAPIInteractor.rejectUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
                    },
                    .cancel()
                ])
            }
        }
        
    }
}
