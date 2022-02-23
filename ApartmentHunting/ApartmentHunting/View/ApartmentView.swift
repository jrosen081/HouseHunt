//
//  ApartmentView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import Foundation
import SwiftUI

struct ApartmentView: View {
    @Binding var apartment: ApartmentModel
    @Binding var overlay: ApartmentsViewOverlay?
    @Binding var showingSelected: Bool
    @State private var dateShowing = Date().addingTimeInterval(60 * 60 * 24)
    @State private var addingOpinion = false
    @State private var showingShareSheet = false
    @State private var confirmDialog = false
    @State private var onDisappear: (() -> Void)?
    @State private var visibleOpinion: Opinion?
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    @CurrentUserState var user
    @EnvironmentObject var search: ApartmentSearch
    
    private var hasSelectedApartment: Bool {
        search.acceptedHouse != nil
//        return false
    }
    
    private func updateApartment(state: ApartmentState, previousStates: [ApartmentState]? = nil) {
        var newApartment = apartment
        newApartment.previousStates = previousStates ?? ((newApartment.previousStates ?? []) + [newApartment.state])
        newApartment.state = state
        ApartmentAPIInteractor.update(apartment: newApartment)
        self.apartment = newApartment
    }
    
    @ViewBuilder
    private func actionsView<Content: View>(@ViewBuilder views: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions:").font(.headline).padding(.top).accessibilityHidden(true)
            views()
        }
    }
    
    @ViewBuilder
    private var stateView: some View {
        switch apartment.state {
        case .seeing(let date):
            let opinionView = AddOpinionView(isEditable: true) { opinion in
                if let opinion = opinion {
                    updateApartment(state: .opinions(opinions: [opinion]))
                }
                self.overlay = nil
            }
            Text("Seeing on \(dateFormatter.string(from: date))").font(.subheadline)
                .accessibilityLabel("Current State: Seeing on \(dateFormatter.string(from: date))")
            
            actionsView {
                RoundedButton(title: "Add Your Opinion", color: .primary) {
                    #if os(iOS)
                    self.addingOpinion = true
                    #else
                    self.overlay = .addOpinion(opinionView)
                    #endif
                }.sheet(isPresented: $addingOpinion) {
                    NavigationView {
                        opinionView
                    }
                }
            }.disabled(hasSelectedApartment)
        case .interested:
            Text("We are interested in this home").font(.subheadline)
                .accessibilityLabel("Current State: We are interested in this home")
            actionsView {
                RoundedButton(title: "I reached out to the broker", color: .primary) {
                    updateApartment(state: .reachedOutToBroker)
                }
                RoundedButton(title: "We don't want this place", color: .red, action: {
                    updateApartment(state: .uninterested)
                })
            }.disabled(hasSelectedApartment)
        case .unsure:
            Text("We are unsure about the home").font(.subheadline)
                .accessibilityLabel("Current State: We are unsure about the home")
            actionsView {
                RoundedButton(title: "I reached out to the broker", color: .primary) {
                    updateApartment(state: .reachedOutToBroker)
                }
                RoundedButton(title: "We don't want this place", color: .red, action: {
                    updateApartment(state: .uninterested)
                })
            }.disabled(hasSelectedApartment)
        case .uninterested:
            Text("We are no longer interested in this one anymore").font(.subheadline)
                .accessibilityLabel("Current State: We are no longer interested in this one anymore")
        case .reachedOutToBroker:
            Text("We reached out to owner").font(.subheadline)
                .accessibilityLabel("Current State: We reached out to owner")
            actionsView {
                Text("When did you set a time to see the home?")
                    .accessibilityHidden(true)
                DatePicker("When did you set a time to see the home?", selection: $dateShowing, in: Date()...)
                    .labelsHidden()
                    .padding(.bottom)
                RoundedButton(title: "Set Viewing Date", color: .primary, action: {
                    updateApartment(state: .seeing(date: self.dateShowing))
                })
            }.disabled(hasSelectedApartment)
        case .opinions(let opinions):
            let opinionView = AddOpinionView(isEditable: true) { opinion in
                if let opinion = opinion {
                    updateApartment(state: .opinions(opinions: opinions + [opinion]))
                }
                self.overlay = nil
            }
            Text("We saw the house").font(.subheadline)
                .accessibilityLabel("Current State: We saw the house")
            actionsView {
                ForEach(opinions) { opinion in
                    RoundedButton(title: "See \(opinion.author)'s opinion", color: .primary) {
                        #if os(iOS)
                        self.visibleOpinion = opinion
                        #else
                        let opinionView = OpinionView(opinion: Binding.constant(opinion), onFinish: {_ in
                            self.overlay = nil
                        }, isEditable: false)
                        self.overlay = .viewOpinion(opinionView)
                        #endif
                    }
                }.sheet(item: $visibleOpinion) { opinion in
                    NavigationView {
                        OpinionView(opinion: .constant(opinion), onFinish: {_ in }, isEditable: false)
                    }
                }
                .sheet(isPresented: $addingOpinion) {
                    NavigationView {
                        opinionView
                    }
                }
                if !opinions.contains(where: { $0.author == user.name }) {
                    RoundedButton(title: "Add Your Opinion", color: .primary, action: {
                        #if os(iOS)
                        self.addingOpinion = true
                        #else
                        self.overlay = .addOpinion(opinionView)
                        #endif
                    }).disabled(hasSelectedApartment)
                }
                if !hasSelectedApartment {
                    RoundedButton(title: "We Got This Home", color: .green) {
                        self.confirmDialog = true
                    }.alert(isPresented: $confirmDialog) {
                        Alert(title: Text("Confirm that you got this home"), message: Text("Once you have accepted this house, you won't be able to edit this Home Search"), primaryButton: .default(Text("We Got It"), action: {
                            self.updateApartment(state: .selected)
                            ApartmentAPIInteractor.setSelectedHouse(apartmentSearch: self.search, houseId: self.apartment.id!)
                        }), secondaryButton: .cancel(Text("Nevermind")))
                    }
                }
            }
        case .selected:
            Text("We have selected this home!").font(.subheadline).bold()
                .accessibilityLabel("Current State: We have selected this home!")
            actionsView {
                RoundedButton(title: "Hide Full Search", color: .primary) {
                    self.showingSelected = true
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(apartment.location)
                    .font(.headline)
                    .accessibility(addTraits: .isHeader)
                Spacer()
                if let url = URL(string: apartment.url) {
                    #if os(macOS)
                    if let previousStates = apartment.previousStates, let prevState = previousStates.last {
                        Button(action: {
                            updateApartment(state: prevState, previousStates: Array(previousStates.dropLast()))
                        }) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }.disabled(hasSelectedApartment)
                    }
                    Button(action: {
                        self.showingShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }.shareSheet(items: [url], isPresented: $showingShareSheet)
                    #else
                    Menu(content: {
                        if let previousStates = apartment.previousStates, let prevState = previousStates.last {
                            Button(action: {
                                updateApartment(state: prevState, previousStates: Array(previousStates.dropLast()))
                            }) {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                            }.disabled(hasSelectedApartment)
                        }
                        Button(action: {
                            self.showingShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }, label: {
                        Image(systemName: "ellipsis.circle").resizable().scaledToFit().frame(height: 25).foregroundColor(.primary)
                    }).shareSheet(items: [url], isPresented: $showingShareSheet)
                    #endif
                        
                }
            }
            LinkView(linkUrl: URL(string: apartment.url)).frame(maxWidth: .infinity)
            Text("Notes:").font(.headline).accessibilityHidden(true)
            Text(apartment.notes)
                .padding(.bottom)
                .accessibilityLabel("Notes:  \(apartment.notes)")
            Text("Current State:").font(.headline).accessibilityHidden(true)
            stateView
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity)
        .onAppear {
            let listener = ApartmentAPIInteractor.listenForChanges(apartment: $apartment.animation())
            self.onDisappear = {
                listener.remove()
            }
        }.onDisappear(perform: onDisappear)
    }
}
