//
//  ApartmentRequestView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/28/22.
//

import SwiftUI

struct Tabs<Value: Identifiable>: View {
    let allTabs: [Value]
    @Binding var selectedTab: Value
    let viewBuilder: (Value) -> String
    @Namespace var namespace
    @Environment(\.sizeCategory) var size
    
    
    private var fontSize: Font {
        size > .medium ? Font.footnote : Font.callout
    }
    
    @ViewBuilder
    private func overlay(tab: Value) -> some View {
        if tab.id == selectedTab.id {
            VStack {
                Spacer()
                Rectangle().frame(height: 2)
            }.matchedGeometryEffect(id: "fun", in: namespace)
        }
    }
    
    var body: some View {
        HStack {
            ForEach(allTabs) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(viewBuilder(tab))
                        .font(fontSize.weight(.semibold))
                        .padding(.bottom, 4)
                        .overlay(overlay(tab: tab))
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }.coordinateSpace(name: namespace)
            .multilineTextAlignment(.center)
    }
}

struct ApartmentRequestView: View {
    enum ViewState: String, Identifiable, Hashable {
        case createNew = "CREATE SEARCH"
        case join = "JOIN SEARCH"
        
        var id: Self { self }
    }
    @EnvironmentObject var authInteractor: AuthInteractor
    @CurrentUserState var user: User
    @State private var state = ViewState.createNew
    @State private var loadingState = LoadingState<Bool>.notStarted
    @State private var info = ""
    
    private func view(for state: ViewState) -> some View {
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
            NavigationLink(tag: ViewState.join, selection: Binding($state), destination: { view(for: .join) }) {
                Label("Join", systemImage: "magnifyingglass")
            }
            NavigationLink(tag: ViewState.createNew, selection: Binding($state), destination: { view(for: .createNew) }) {
                Label("Create New", systemImage: "plus")
            }
        }.listStyle(.sidebar)
        #else
        VStack {
            Tabs(allTabs: [ViewState.createNew, .join], selectedTab: $state, viewBuilder: \.rawValue)
                .padding(.top)
            Divider()
            TabView(selection: $state) {
                view(for: .createNew)
                    .tag(ViewState.createNew)
                view(for: .join)
                    .tag(ViewState.join)
            }.tabViewStyle(.page(indexDisplayMode: .never))
        }
        .animation(.default, value: state)
        
        #endif
    }
}

struct ApartmentRequestView_Previews: PreviewProvider {
    static var previews: some View {
        ApartmentRequestView()
    }
}
