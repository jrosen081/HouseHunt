//
//  ApartmentRequestView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/28/22.
//

import SwiftUI

struct ApartmentRequestView: View {
    enum ViewState {
        case createNew
        case join
    }
    @EnvironmentObject var authInteractor: AuthInteractor
    @CurrentUserState var user: User
    @State private var state = ViewState.join
    @State private var loadingState = LoadingState<Bool>.notStarted
    @State private var info = ""
    
    private func view(for state: ViewState, showSwitch: Bool) -> some View {
        VStack(alignment: .leading) {
            switch state {
            case .createNew:
                TextFieldEntry(title: "Home Search Name", text: $info)
            case .join:
                TextFieldEntry(title: "Home Search Join Code", text: $info)
#if !os(macOS)
                    .autocapitalization(.none)
#endif
                    .disableAutocorrection(true)
            }
            Spacer()
            switch loadingState {
            case .notStarted:
                EmptyView()
            case .loading:
                HStack {
                    Spacer()
                    ProgressView("Loading")
                    Spacer()
                }
            case .success(_):
                EmptyView()
            case .error(let string):
                Text(L10n.somethingWentWrong(string)).foregroundColor(.red)
            }
            RoundedButton(title: state == .join ? "Request to Join" : "Create Search", color: .green) {
                switch state {
                case .createNew:
                    let id = ApartmentAPIInteractor.addApartmentSearch(searchCreator: { code in  ApartmentSearchDTO(name: info, users: [user.id!], requests: [], entryCode: code)})
                    var newUser = user
                    newUser.apartmentSearchState = .success(id: id)
                    authInteractor.update(user: newUser)
                case .join:
                    Task {
                        do {
                            self.loadingState = .loading
                            let (requestId, requestName) = try await ApartmentAPIInteractor.requestApartment(currentUser: user, id: info)
                            var newUser = user
                            newUser.apartmentSearchState = .requested(name: requestName, id: requestId)
                            authInteractor.update(user: newUser)
                        } catch {
                            self.loadingState = .error(error.localizedDescription)
                        }
                    }
                }
            }.disabled(info.isEmpty)
            if showSwitch {
                RoundedButton(title: state == .join ? "Switch to Create Search" : "Switch to Request to Join", color: .primary) {
                    self.loadingState = .notStarted
                    switch self.state {
                    case .createNew:
                        self.state = .join
                    case .join:
                        self.state = .createNew
                    }
                }
            }
            RoundedButton(title: "Sign Out", color: .red) {
                authInteractor.signOut()
            }
        }
        .navigationTitle(state == .join ? "Join Search" : "Create Search")
        .padding()
        .removingKeyboardOnTap()
    }
    var body: some View {
        #if os(macOS)
        List {
            NavigationLink(tag: ViewState.join, selection: Binding($state), destination: { view(for: .join, showSwitch: false) }) {
                Label("Join", systemImage: "magnifyingglass")
            }
            NavigationLink(tag: ViewState.createNew, selection: Binding($state), destination: { view(for: .createNew, showSwitch: false) }) {
                Label("Create New", systemImage: "plus")
            }
        }.listStyle(.sidebar)
        #else
        view(for: state, showSwitch: true)
        #endif
    }
}

struct ApartmentRequestView_Previews: PreviewProvider {
    static var previews: some View {
        ApartmentRequestView()
    }
}
