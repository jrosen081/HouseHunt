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
        SwiftUI.Section(content: content, header: { header.accessibilityAddTraits(.isHeader) })
        #else
        GroupBox(content: { VStack(alignment: .leading) { content().frame(maxWidth: .infinity) }.padding().frame(maxWidth: .infinity) }, label: { header.accessibilityAddTraits(.isHeader) }).pickerStyle(.segmented)
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
    @State private var confirmLeaving = false
    
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
                Text("Name").accessibilityHidden(true)
                Spacer()
                Text(apartmentSearch.name)
                    .accessibilityLabel("Name of Home Search is \(apartmentSearch.name)")
            }
            HStack {
                Text("Join Code")
                    .foregroundColor(.primary)
                    .accessibilityHidden(true)
                Spacer()
                Button(action: {
                    Pasteboard.general.string = apartmentSearch.entryCode
                    withAnimation { self.message = "Code Copied" }
                }) {
                    Text(apartmentSearch.entryCode)
                        .foregroundColor(.blue)
                        .accessibilityLabel("Copy Home Search Join Code")
                }.accessibilityHint("Copies the Home Search Join code that you can send to someone else to join your Home Search")
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
                    Text("Search Information")
                        .accessibilityHidden(true)
                    Spacer()
                    Button(action: {
                        Pasteboard.general.string = brokerCode
                        withAnimation { self.message = "Broker Response Copied" }
                    }) {
                        Text("Copy")
                            .accessibilityLabel("Copy Home Search Information")
                    }
                }
            } else {
                #if os(macOS)
                brokerView
                #else
                HStack {
                    Text("Search Information")
                        .accessibilityHidden(true)
                    Spacer()
                    Button(action: {
                        self.showingBrokerInfo = true
                    }) {
                        Text("Add")
                            .accessibilityLabel("Add Home Search Information")
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
    
    private var userInterfacePicker: some View {
        Picker("", selection: self.$initializer.userInterfaceStyle) {
            ForEach([ColorSchemeAdaptor.automatic, ColorSchemeAdaptor.light, ColorSchemeAdaptor.dark], id: \.self) { style in
                Text(style.textualRepresentation)
            }
        }
    }
    
    @ViewBuilder
    private var displaySection: some View {
        Section(header: Text("Display")) {
            HStack {
                Text("Theme")
                    .accessibilityHidden(true)
                Spacer()
                Group {
#if !os(macOS)
                    Menu {
                        userInterfacePicker
                    } label: {
                        Text(self.initializer.userInterfaceStyle.textualRepresentation)
                    }
#else
                    userInterfacePicker
#endif
                }.accessibilityLabel("Current Theme: \(self.initializer.userInterfaceStyle.textualRepresentation)")
                
                
            }
            
        }
    }
    
    @ViewBuilder
    var dangerZoneSection: some View {
        Section(header: Text("Danger Zone")) {
            Button("Leave Home Search") {
                self.confirmLeaving = true
            }.foregroundColor(.red)
                .alert(isPresented: $confirmLeaving) {
                    Alert(title: Text("Are you sure?"), message: Text("Once you leave, you will need to be accepted again to re-join."), primaryButton: .destructive(Text("Yes"), action: {
                        ApartmentAPIInteractor.rejectUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
                    }), secondaryButton: .cancel())
                }
            Button("Sign Out") {
                authInteractor.signOut()
            }.foregroundColor(.red)
        }
        #if os(macOS)
        .buttonStyle(RoundedButtonStyle(color: .red, enabled: true))
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
                if #available(iOS 15, macOS 15, *) {
                    displaySection
                }
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
                .accessibilityHidden(true)
            Spacer()
            Button(action: {
                self.administering = true
            }) {
                Text("Manage")
                    .accessibilityLabel("Manage \(user.name)'s request to join ")
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
