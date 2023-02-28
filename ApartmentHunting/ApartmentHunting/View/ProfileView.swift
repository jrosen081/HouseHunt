//
//  ProfileView.swift
//  HomeHunt
//
//  Created by Jack Rosen on 3/16/22.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authInteractor: AuthInteractor
    @CurrentUserState var user
    @State private var name = ""
    @State private var confirmLeaving = false
    @State private var leavingState: LoadingState<Double> = .notStarted
    @EnvironmentObject private var apartmentSearch: ApartmentSearch
    @Environment(\.back_dismiss) var dismiss
    
    @ViewBuilder
    var dangerZoneSection: some View {
        Section(header: Text("Danger Zone")) {
            if case .success(_) = user.apartmentSearchState {
                Button("Leave Home Search") {
                    self.confirmLeaving = true
                }.foregroundColor(.red)
                    .foregroundColor(.red)
                    .disabled(self.leavingState == .loading)
                    .opacity(self.leavingState != .loading ? 1 : 0.2)
                    .alert(isPresented: $confirmLeaving) {
                        Alert(title: Text("Are you sure?"), message: Text("Once you leave, you will need to be accepted again to re-join."), primaryButton: .destructive(Text("Yes"), action: {
                            Task { @MainActor in
                                self.leavingState = .loading
                                do {
                                    try await ApartmentAPIInteractor.leaveApartmentSearch()
                                    dismiss()
                                } catch {
                                    self.leavingState = .error("")
                                }
                                
                            }
                            
                        }), secondaryButton: .cancel())
                    }
                    .overlay (
                        ProgressView()
                            .opacity(self.leavingState == .loading ? 1 : 0)
                    )
            }
            Button("Sign Out") {
                dismiss()
                authInteractor.signOut()
            }
        }
#if os(macOS)
        .buttonStyle(RoundedButtonStyle(color: .red, enabled: true))
#endif
    }
    var body: some View {
        List {
            Section(header: Text("User Information")) {
                VStack {
                    TextFieldEntry(title: "Name", text: $name)
                    #if os(iOS)
                        .padding(.bottom)
                    #endif
                    RoundedButton(title: "Save", color: .green, paddingAmount: 5) {
                        let newUser = User(id: user.id, apartmentSearchState: user.apartmentSearchState, name: name)
                        authInteractor.update(user: newUser)
                    }.disabled(name == user.name)
                }
            }
            dangerZoneSection
        }
        .navigationTitle("Profile")
        .onAppear {
            self.name = user.name
        }
        .analyticsScreen(name: "user_profile")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
