//
//  SearchView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/30/22.
//

import SwiftUI

#if os(macOS)
typealias Pasteboard = NSPasteboard
extension NSPasteboard {
    var string: String? {
        get {
            return self.string(forType: .string)
        }
        set {
            if let value = newValue {
                self.declareTypes([.string], owner: nil)
                self.setString(value, forType: .string)
            }
        }
    }
}
#else
typealias Pasteboard = UIPasteboard
#endif

struct Section<Header: View, Content: View>: View {
    let header: Header
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        #if os(iOS)
        SwiftUI.Section(content: content, header: { header }).pickerStyle(.menu)
        #else
        GroupBox(content: { VStack(alignment: .leading) { content().frame(maxWidth: .infinity) }.padding().frame(maxWidth: .infinity) }, label: { header }).pickerStyle(.segmented)
        #endif
    }
}


struct SettingsView: View {
    @CurrentUserState private var user
    @EnvironmentObject private var apartmentSearch: ApartmentSearch
    @EnvironmentObject private var authInteractor: AuthInteractor
    @EnvironmentObject private var initializer: Initializer
    @State private var message: String? = nil
    @State private var showingBrokerInfo = false
    
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
                Text("Name")
                Spacer()
                Text(apartmentSearch.name)
            }
            HStack {
                Text("Join Code")
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    Pasteboard.general.string = apartmentSearch.entryCode
                    withAnimation { self.message = "Code Copied" }
                }) {
                    Text(apartmentSearch.entryCode)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    var brokerInteractionSection: some View {
        let brokerView = AddBrokerInformationView { brokerResponse in
            ApartmentAPIInteractor.updateBrokerComment(apartmentSearch: self.apartmentSearch, comment: brokerResponse)
        }
        Section(header: Text("Broker Interactions")) {
            if let brokerCode = apartmentSearch.brokerResponse {
                HStack {
                    Text("Hunt Information")
                    Spacer()
                    Button(action: {
                        Pasteboard.general.string = brokerCode
                        withAnimation { self.message = "Broker Response Copied" }
                    }) {
                        Text("Copy")
                    }
                }
            } else {
                #if os(macOS)
                brokerView
                #else
                HStack {
                    Text("Hunt Information")
                    Spacer()
                    Button(action: {
                        self.showingBrokerInfo = true
                    }) {
                        Text("Add")
                    }
                }
                .sheet(isPresented: $showingBrokerInfo) {
                    NavigationView {
                        brokerView
                            .navigationTitle(Text("Add Information"))
                            .padding()
                    }
                }
                #endif
            }
        }
    }
    
    @ViewBuilder
    private var displaySection: some View {
        Section(header: Text("Display")) {
            HStack {
                Text("Theme")
                Spacer()
                Picker("", selection: self.$initializer.userInterfaceStyle) {
                    ForEach([ColorSchemeAdaptor.automatic, ColorSchemeAdaptor.light, ColorSchemeAdaptor.dark], id: \.self) { style in
                        switch style {
                        case .automatic: Text("System Defined")
                        case .light: Text("Light Mode")
                        case .dark: Text("Dark Mode")
                        }
                    }
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
        #if os(macOS)
        .buttonStyle(RoundedButtonStyle(color: .red))
        #endif
    }
    
    @ViewBuilder
    var overlayView: some View {
        if let message = message {
            Text(message)
                .padding()
                .background(Capsule().fill(.green))
                .padding(.bottom)
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
                displaySection
                dangerZoneSection
            }.navigationTitle("Settings")
            #if !os(macOS)
                .listStyle(.insetGrouped)
            #endif
            overlayView
        }
        .toolbar {
            ToolbarItem {
                HStack {
                    EmptyView()
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
            }.back_confirmationDialog(isPresented: $administering, title: Text("Manage User")) {
                [
                    $0.default(message: Text("Accept"), action: {
                        ApartmentAPIInteractor.acceptUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
                    }),
                    $0.destructive(message: Text("Reject")) {
                        ApartmentAPIInteractor.rejectUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
                    },
                    $0.cancel()
                ]
            }
        }
        
    }
}
