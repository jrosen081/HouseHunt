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
            TabView {
                NavigationView {
                    ApartmentsView()
                }.tabItem {
                    Text("Search")
                    Image(systemName: "house")
                }
                NavigationView {
                    SettingsView()
                }.tabItem {
                    Text("Settings")
                    Image(systemName: "gear")
                }
            }
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
