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
    @State private var location: Location = .apartments
    var isApartmentsActive: Binding<Bool> {
        Binding(get: { location == .apartments}) { location = $0 ? .apartments : .settings}
    }
    
    var isSettingsActive: Binding<Bool> {
        Binding(get: { location == .settings}) { location = $0 ? .settings : .apartments}
    }
    var body: some View {
        if shouldShowLargeView {
            NavigationView {
                List {
                    NavigationLink(destination: ApartmentsView(), isActive: isApartmentsActive) {
                        Label("Homes", systemImage: "house")
                    }
                    NavigationLink(destination: SettingsView(), isActive: isSettingsActive) {
                        Label("Settings", systemImage: "gear")
                    }.keyboardShortcut(",", modifiers: .command)
                }.listStyle(.sidebar).padding(.top)
                    .navigationTitle("Home Hunt")
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
    }
}

