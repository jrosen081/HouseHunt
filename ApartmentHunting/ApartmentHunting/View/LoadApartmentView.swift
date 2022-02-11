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
    @State private var isApartmentsActive = true
    
    var body: some View {
        if shouldShowLargeView {
            NavigationView {
                List {
                    NavigationLink(destination: ApartmentsView(), isActive: $isApartmentsActive) {
                        Label("Homes", systemImage: "house")
                    }
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
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

