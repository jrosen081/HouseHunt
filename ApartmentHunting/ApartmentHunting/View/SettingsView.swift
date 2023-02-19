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
    private enum Overlay: Identifiable {
        case profile, brokerInfo
        
        var id: Self {
            return self
        }
    }
    
    @CurrentUserState private var user
    @EnvironmentObject private var apartmentSearch: ApartmentSearch
    @EnvironmentObject private var authInteractor: AuthInteractor
    @EnvironmentObject private var initializer: Initializer
    @State private var message: String? = nil
    @State private var overlay: Overlay?
    
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
    
    var brokerView: some View {
        AddBrokerInformationView { brokerResponse in
            ApartmentFirebaseInteractor.updateBrokerComment(apartmentSearch: self.apartmentSearch, comment: brokerResponse)
        }
    }
    
    @ViewBuilder
    var brokerInteractionSection: some View {
        
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
                        self.overlay = .brokerInfo
                    }) {
                        Text("Add")
                            .accessibilityLabel("Add Home Search Information")
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
        ZStack {
            ZStack(alignment: .bottom) {
                List {
                    requestsSection
                    homeInfoSection
                    brokerInteractionSection
                    if #available(iOS 15, macOS 15, *) {
                        displaySection
                    }
                }
#if !os(macOS)
                    .listStyle(.insetGrouped)
#endif
                overlayView
            }
            
            #if os(iOS)
            .sheet(item: $overlay) { overlay in
                NavigationView {
                    switch overlay {
                    case .brokerInfo:
                        brokerView
                            .navigationTitle(Text("Add Information"))
                            .padding()
                    case .profile:
                        ProfileView()
                    }
                }
                
            }
            #endif
            #if os(macOS)
            if overlay == .profile {
                ProfileView()
                    .transition(.move(edge: .bottom))
                    .animation(.linear, value: self.overlay == nil)
            }
            #endif
                
        }.navigationTitle("Settings")
            .toolbar {
                ToolbarItem {
                    #if os(iOS)
                    Button {
                        self.overlay = .profile
                    } label: {
                        Label("Show Profile", systemImage: "person.circle")
                            .foregroundColor(.primary)
                    }
                    #else
                    if self.overlay != .profile {
                        Button {
                            self.overlay = .profile
                        } label: {
                            Label("Show Profile", systemImage: "person.circle")
                                .foregroundColor(.primary)
                        }
                    } else {
                        Button {
                            self.overlay = nil
                        } label: {
                            Text("Hide Profile")
                        }
                    }
                    #endif
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
                        ApartmentFirebaseInteractor.acceptUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
                    }),
                    $0.destructive(message: Text("Reject")) {
                        ApartmentFirebaseInteractor.rejectUser(apartmentSearch: apartmentSearch, user: user, authInteractor: authInteractor)
                    },
                    $0.cancel()
                ]
            }
        }
        
    }
}
