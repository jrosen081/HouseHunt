//
//  LoadApartmentView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/30/22.
//

import SwiftUI

struct LoadApartmentView: View {
    let id: String
    @State private var loadingState = LoadingState<ApartmentSearch>.notStarted
    @EnvironmentObject var authInteractor: AuthInteractor
    @State private var onDisappear: (() -> Void)?
    var body: some View {
        switch loadingState {
        case .notStarted, .loading:
            NavigationView {
                ProgressView("Loading Houses")
                    .back_task {
                        do {
                            let apartment = try await ApartmentAPIInteractor.getApartmentSearch(id: id, authInteractor: authInteractor)
                            await MainActor.run {
                                self.loadingState = .success(apartment)
                            }
                        } catch {
                            await MainActor.run {
                                self.loadingState = .error(error.localizedDescription)
                            }
                        }
                    }.navigationTitle("Homes")
            }
            
        case .success(let apartmentSearch):
            MainView()
            .environmentObject(apartmentSearch)
            .onDisappear(perform: self.onDisappear)
            .onAppear {
                let binding = Binding<ApartmentSearch>(get: { apartmentSearch }) {
                    self.loadingState = .success($0)
                }
                let token = ApartmentAPIInteractor.listenForChanges(apartmentSearch: binding, authInteractor: authInteractor)
                self.onDisappear = { [token] in
                    token.remove()
                }
            }
        case .error(_):
            ErrorView {
                self.loadingState = .notStarted
            }
            
        }
    }
}


let shouldShowLargeView: Bool = {
#if os(macOS)
    return true
#else
    return UIDevice.current.userInterfaceIdiom == .pad
#endif
}()

private struct MainView: View {
    private enum Location { case apartments, settings}
    @State private var location: Location? = .apartments
    
    private func background(location: Location) -> some View {
        Group {
            self.location == location ? Color.gray.opacity(0.3) : Color.clear
        }.cornerRadius(10)
    }

    var body: some View {
        GeometryReader { proxy in
            #if os(macOS)
            NavigationView {
                List {
                    NavigationLink(tag: Location.apartments, selection: $location, destination: { ApartmentsView() }) {
                        Label("Homes", systemImage: "house")
                    }.keyboardShortcut("1", modifiers: .command)
                    NavigationLink(tag: Location.settings, selection: $location, destination: { SettingsView() }) {
                        Label("Settings", systemImage: "gear")
                    }.keyboardShortcut(",", modifiers: .command)
                    Button("Settings") { self.location = .settings }.frame(width: 0, height: 0).opacity(0).keyboardShortcut("2")
                }.listStyle(.sidebar).navigationTitle("Home Hunt").buttonStyle(.plain)
                    .padding(.top)
            }
            #else
            if proxy.size.width > 600 {
                /// DUE TO iPADOS issues, this needs a custom look to open right away
                NavigationView {
                    List {
                        Button(action: { self.location = .apartments }, label: { Label("Homes", systemImage: "house") })
                            .keyboardShortcut("1", modifiers: .command)
                            .padding(.horizontal, 5)
                            .listRowBackground(background(location: .apartments))
                        Button(action: { self.location = .settings }, label: { Label("Settings", systemImage: "gear") })
                            .keyboardShortcut(",", modifiers: .command)
                            .padding(.horizontal, 5)
                            .listRowBackground(background(location: .settings))
                        Button("Settings") { self.location = .settings }.frame(width: 0, height: 0).opacity(0).keyboardShortcut("2")
                    }.listStyle(.sidebar).navigationTitle("Home Hunt").buttonStyle(.plain)
#if os(macOS)
                        .padding(.top)
#endif
                    Group {
                        switch self.location {
                        case .settings:
                            SettingsView()
                        case .apartments:
                            ApartmentsView()
                        }
                    }.animation(nil, value: self.location)
                }
            } else {
                TabView {
                    NavigationView {
                        ApartmentsView()
                    }.tabItem {
                        Text("Homes")
                        Image(systemName: "house")
                    }
                    NavigationView {
                        SettingsView()
                    }.tabItem {
                        Text("Settings")
                        Image(systemName: "gear")
                    }
                }
            }
            #endif
        }
        
    }
}

