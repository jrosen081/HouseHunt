//
//  ApartmentsView.swift
//  Apartments
//
//  Created by Jack Rosen on 1/22/22.
//

import SwiftUI

struct ApartmentsView: View {
    @State private var loadingState = LoadingState<[ApartmentModel]>.notStarted
    @State private var addingApartment = false
    @State private var search = ""
    @State private var filter: ApartmentAddingState = .all
    @State private var currentUser = ""
    @Environment(\.scenePhase) var phase
    @CurrentUserState var user: User
    @EnvironmentObject var apartmentSearch: ApartmentSearch
    
    func loadPosts() async {
        self.loadingState = .loading
        do {
            self.loadingState = try await .success(ApartmentAPIInteractor.getApartments(id: apartmentSearch.id))
        } catch {
            self.loadingState = .error(error.localizedDescription)
        }
    }
    
    func hasFilteredState(apartment: ApartmentModel) -> Bool {
        switch (filter, apartment.state) {
        case (.all, _): return true
        case (.uninterested, .uninterested),
            (.interested, .interested),
            (.unsure, .unsure),
            (.reachedOutToBroker, .reachedOutToBroker),
            (.seeing, .seeing(_)),
            (.opinion, .opinions(_)):
            return true
        default: return false
        }
    }
    
    func isForCorrectUser(apartment: ApartmentModel) -> Bool {
        apartment.author == currentUser || currentUser == ""
    }
    
    func include(apartment: ApartmentModel) -> Bool {
        let includedInSearch = apartment.location.lowercased().contains(search.lowercased()) || apartment.url.lowercased().contains(search.lowercased()) || search == ""
        return includedInSearch && hasFilteredState(apartment: apartment) && isForCorrectUser(apartment: apartment)
    }
    
    @ViewBuilder
    private var mainView: some View {
        switch loadingState {
        case .notStarted, .loading:
            ProgressView("Loading Homes")
                .back_task {
                    await loadPosts()
                }
        case .success(let apartments):
            let apartmentsBinding = Binding(get: {
                apartments
            }, set: {
                self.loadingState = .success($0)
            })
            Group {
                if apartments.isEmpty {
                    RoundedButton(title: "Add the first home to your search", color: .green) {
                        self.addingApartment = true
                    }.padding(.horizontal)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(apartmentsBinding) { $apartment in
                                if include(apartment: apartment) {
                                    ApartmentView(apartment: $apartment).padding(.horizontal)
                                    Rectangle().frame(height: 3).foregroundColor(.primary).padding(.vertical)
                                }
                            }
                        }.back_searchable(text: $search, prompt: "Filter by title")
                    }
                }
            }
            
        case .error(let string):
            Text("Error: \(string), going to retry")
                .back_task {
                    try? await Task.sleep(nanoseconds: 1000000000 * 1)
                    await self.loadPosts()
                }
        }
    }
    
    var body: some View {
        mainView.onChange(of: phase) { phase in
            if phase == .active {
                self.loadingState = .loading
            }
        }.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    self.loadingState = .notStarted
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        self.addingApartment = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                    Menu(content: {
                        Picker("Filter", selection: $filter.animation()) {
                            let allFilterCases: [ApartmentAddingState] = [ApartmentAddingState.all] + ApartmentAddingState.allCases + [ApartmentAddingState.opinion, ApartmentAddingState.uninterested]
                            ForEach(allFilterCases, id: \.self) { state in
                                Text(state.rawValue)
                            }
                        }
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.primary)
                    }
                    Menu {
                        Picker("Author", selection: $currentUser) {
                            Text("All").tag("")
                            ForEach(apartmentSearch.users) { user in
                                Text(user.name).tag(user.id!)
                            }
                        }
                    } label: {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }.navigationBarTitle("Homes").sheet(isPresented: $addingApartment, onDismiss: {
            self.loadingState = .notStarted
        }) {
            NavigationView {
                AddApartmentView()
                    .navigationTitle("Add Home")
            }
        }.disabled(self.loadingState == .loading || self.loadingState == .notStarted)
    }
}

enum ApartmentAddingState: String, CaseIterable {
    case interested = "Interested"
    case unsure = "Unsure"
    case reachedOutToBroker = "Reached Out to Broker"
    case seeing = "Set up time to See"
    case all = "All"
    case uninterested = "Uninterested"
    case opinion = "Opinion Posted"
    
    static var allCases: [ApartmentAddingState] = [.interested, .reachedOutToBroker, .seeing, .unsure]
}
