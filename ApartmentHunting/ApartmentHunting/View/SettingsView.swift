//
//  SearchView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/30/22.
//

import SwiftUI

struct SettingsView: View {
    @CurrentUserState private var user
    @EnvironmentObject private var apartmentSearch: ApartmentSearch
    @EnvironmentObject private var authInteractor: AuthInteractor
    @State private var message: String? = nil
    @State private var brokerResponse = ""
    
    @ViewBuilder
    private var requestsSection: some View {
        if !apartmentSearch.requests.isEmpty {
            Section(header: Text("Join Requests")) {
                ForEach(apartmentSearch.requests) { user in
                    AcceptRejectView(user: user)
                }
            }
        }
    }
    
    @ViewBuilder
    private var homeInfoSection: some View {
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
    }
    
    @ViewBuilder
    var brokerInteractionSection: some View {
        Section(header: Text("Broker Interactions")) {
            if let brokerCode = apartmentSearch.brokerResponse {
                Button(action: {
                    UIPasteboard.general.string = brokerCode
                    withAnimation { self.message = "Broker Response Copied" }
                }) {
                    Text("Copy Home Information for Broker")
                }
            } else {
                VStack(alignment: .leading) {
                    Text("Home Information To Send to Brokers")
                        .font(.headline)
                        .bold()
                    TextEditor(text: $brokerResponse)
                        .frame(minHeight: 100)
                        .padding(2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke())
                    RoundedButton(title: "Save", color: .green) {
                        ApartmentAPIInteractor.updateBrokerComment(apartmentSearch: self.apartmentSearch, comment: brokerResponse)
                    }.disabled(brokerResponse.isEmpty)
                }
            }
        }
    }
    
    @ViewBuilder
    var dangerZoneSection: some View {
        Section(header: Text("Danger Zone")) {
            Button("Leave Home Search") {
                ApartmentAPIInteractor.rejectUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
            }.foregroundColor(.red)
            Button("Sign Out") {
                authInteractor.signOut()
            }.foregroundColor(.red)
        }
    }
    
    @ViewBuilder
    var overlayView: some View {
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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                requestsSection
                homeInfoSection
                brokerInteractionSection
                dangerZoneSection
            }.navigationTitle("Settings")
                .listStyle(.insetGrouped)
            overlayView
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
