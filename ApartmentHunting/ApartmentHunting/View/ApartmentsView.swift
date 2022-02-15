//
//  ApartmentsView.swift
//  Apartments
//
//  Created by Jack Rosen on 1/22/22.
//

import SwiftUI

enum ApartmentsViewOverlay {
    case addOpinion(AddOpinionView)
    case viewOpinion(OpinionView)
    case addHouse(AddApartmentView)
}

struct ApartmentsView: View {
    @State private var loadingState = LoadingState<[ApartmentModel]>.notStarted
    @State private var addingApartment = false
    @State private var search = ""
    @State private var filter: ApartmentAddingState = .all
    @State private var currentUser = ""
    @State private var showingFinalApartment = true
    @Environment(\.scenePhase) var phase
    @CurrentUserState var user: User
    @EnvironmentObject var apartmentSearch: ApartmentSearch
    @State private var overlay: ApartmentsViewOverlay?
    
    private var shouldDisableToolbar: Bool {
        switch loadingState {
        case .notStarted, .loading, .error(_):
            return true
        case .success(_):
            return apartmentSearch.acceptedHouse != nil
        }
    }
    
    func setAddApartment(_ val: Bool) {
        #if os(macOS)
        self.overlay = .addHouse(AddApartmentView { self.overlay = nil })
        #else
        self.addingApartment = true
        #endif
    }
    
    
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
            (.opinion, .opinions(_)),
            (.selected, .selected):
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
                        self.setAddApartment(true)
                    }.padding(.horizontal)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(apartmentsBinding) { $apartment in
                                if include(apartment: apartment) {
                                    ApartmentView(apartment: $apartment, overlay: $overlay.animation()).padding(.horizontal)
                                    Rectangle().frame(height: 3).foregroundColor(.primary).padding(.vertical)
                                }
                            }
                        }
                        #if os(macOS)
                            .padding(.top)
                        #endif
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
    
    private var authorView: some View {
        Picker("Author", selection: $currentUser) {
            Text("All").tag("")
            ForEach(apartmentSearch.users) { user in
                Text(user.name).tag(user.id!)
            }
        }
    }
    
    private var stateView: some View {
        Picker("Current State", selection: $filter.animation()) {
            let allFilterCases: [ApartmentAddingState] = [ApartmentAddingState.all, ApartmentAddingState.selected] + ApartmentAddingState.allCases + [ApartmentAddingState.opinion, ApartmentAddingState.uninterested]
            ForEach(allFilterCases, id: \.self) { state in
                Text(state.rawValue)
            }
        }
    }
    
    private var reloadView: some View {
        Button(action: {
            self.loadingState = .notStarted
        }) {
            Label("Refresh", systemImage: "arrow.clockwise").foregroundColor(.primary)
        }.keyboardShortcut("r")
    }
    
    @ViewBuilder
    private var notShowingSuccessfulView: some View {
        ZStack {
            mainView
            if let overlay = overlay {
                Group {
                    switch overlay {
                    case .addOpinion(let addOpinionView):
                        addOpinionView
                    case .viewOpinion(let opinionView):
                        opinionView
                    case .addHouse(let addApartmentView):
                        ZStack {
                            List {}.frame(maxWidth: .infinity, maxHeight: .infinity)
                            addApartmentView
                        }
                        
                    }
                }.transition(.move(edge: .bottom))
            } else {
                EmptyView().back_searchable(text: $search, prompt: "Filter by title")
            }
        }
        .onChange(of: phase) { phase in
            if phase == .active {
                DispatchQueue.main.async {
                    self.loadingState = .loading
                }
            }
        }.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if !shouldShowLargeView {
                    reloadView
                }
            }
            ToolbarItem(placement: .primaryAction) {
                if self.overlay == nil {
                    HStack {
                        if shouldShowLargeView {
                            reloadView
                        }
                        if self.apartmentSearch.acceptedHouse == nil {
                            Button(action: {
                                self.setAddApartment(true)
                            }) {
                                Image(systemName: "plus")
                                    .foregroundColor(.primary)
                            }
                        }
                        Menu(content: {
                            stateView
#if os(macOS)
                            authorView
#endif
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.primary)
                        }
#if !os(macOS)
                        Menu {
                            authorView
                        } label: {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .foregroundColor(.primary)
                        }
#endif
                    }
                }
                
            }
        }.navigationTitle("Homes").sheet(isPresented: $addingApartment, onDismiss: {
            self.loadingState = .notStarted
        }) {
            NavigationView {
                AddApartmentView() {}
                .navigationTitle("Add Home")
#if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
            }
        }
    }
    
    var body: some View {
        if let selectedApartment = apartmentSearch.acceptedHouse, showingFinalApartment {
            FoundApartmentView(apartmentModel: selectedApartment, showingFindApartmentView: $showingFinalApartment)
        } else {
            notShowingSuccessfulView
        }
    }
}

enum ApartmentAddingState: String, CaseIterable {
    case interested = "Interested"
    case unsure = "Unsure"
    case reachedOutToBroker = "Contacted Owner"
    case seeing = "Seeing"
    case all = "All"
    case uninterested = "No Longer Interested"
    case opinion = "Opinion Posted"
    case selected = "Selected"
    
    static var allCases: [ApartmentAddingState] = [.interested, .reachedOutToBroker, .seeing, .unsure]
}
