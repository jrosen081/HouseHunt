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
    var body: some View {
        switch loadingState {
        case .notStarted, .loading:
            ProgressView("Loading Apartment")
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
                    SearchView()
                }.tabItem {
                    Text("Settings")
                    Image(systemName: "gearshape")
                }
            }
            
                .environmentObject(apartmentSearch)
        case .error(let string):
            Text("Something went wrong: \(string)")
                .foregroundColor(.red)
        }
    }
}
