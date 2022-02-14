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
    @State private var dateShowing = Date().addingTimeInterval(60 * 60 * 24)
    @State private var addingOpinion = false
    @State private var showingShareSheet = false
    @State private var onDisappear: (() -> Void)?
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    @CurrentUserState var user
    
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
            Text("Actions:").font(.headline).padding(.top)
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
            Text("Seeing \(dateFormatter.string(from: date))").font(.subheadline)
            actionsView {
                RoundedButton(title: "Add Your Opinion", color: .green) {
                    #if os(iOS)
                    self.addingOpinion = true
                    #else
                    self.overlay = .addOpinion(opinionView)
                    #endif
                }.sheet(isPresented: $addingOpinion) {
                    opinionView
                }
            }
        case .interested:
            Text("We are interested in this home").font(.subheadline)
            actionsView {
                RoundedButton(title: "I reached out to the broker", color: .primary) {
                    updateApartment(state: .reachedOutToBroker)
                }
                RoundedButton(title: "We don't want this place", color: .red, action: {
                    updateApartment(state: .uninterested)
                })
            }
        case .unsure:
            Text("We are unsure about the home").font(.subheadline)
            actionsView {
                RoundedButton(title: "I reached out to the broker", color: .primary) {
                    updateApartment(state: .reachedOutToBroker)
                }
                RoundedButton(title: "We don't want this place", color: .red, action: {
                    updateApartment(state: .uninterested)
                })
            }
        case .uninterested:
            Text("We are no longer interested in this one anymore").font(.subheadline)
        case .reachedOutToBroker:
            Text("We reached out to owner").font(.subheadline)
            actionsView {
                Text("When did you set a time to see the home?")
                DatePicker("", selection: $dateShowing, in: Date()...)
                    .labelsHidden()
                    .padding(.bottom)
                RoundedButton(title: "Set Viewing Date", color: .primary, action: {
                    updateApartment(state: .seeing(date: self.dateShowing))
                })
            }
        case .opinions(let opinions):
            let opinionView = AddOpinionView(isEditable: true) { opinion in
                if let opinion = opinion {
                    updateApartment(state: .opinions(opinions: opinions + [opinion]))
                }
                self.overlay = nil
            }
            Text("We saw the house").font(.subheadline)
            actionsView {
                ForEach(opinions, id: \.authorId) { opinion in
                    let opinionView = OpinionView(opinion: Binding.constant(opinion), onFinish: {_ in
                        self.overlay = nil
                    }, isEditable: false)
                    #if os(iOS)
                    NavigationLink("See \(opinion.author)'s opinion", destination: {
                        opinionView
                    }).buttonStyle(RoundedButtonStyle(color: .primary)).padding(.bottom, 1)
                    #else
                    RoundedButton(title: "See \(opinion.author)'s opinion", color: .primary) {
                        self.overlay = .viewOpinion(opinionView)
                    }
                    #endif
                }
                .sheet(isPresented: $addingOpinion) {
                    NavigationView {
                        opinionView
                    }
                }
                if !opinions.contains(where: { $0.author == user.name }) {
                    RoundedButton(title: "Add Your Opinion", color: .green, action: {
                        #if os(iOS)
                        self.addingOpinion = true
                        #else
                        self.overlay = .addOpinion(opinionView)
                        #endif
                    })
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(apartment.location)
                    .font(.headline)
                Spacer()
                if let url = URL(string: apartment.url) {
                    #if os(macOS)
                    if let previousStates = apartment.previousStates, let prevState = previousStates.last {
                        Button(action: {
                            updateApartment(state: prevState, previousStates: Array(previousStates.dropLast()))
                        }) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                        }
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
                            }
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
            Text("Notes:").font(.headline)
            Text(apartment.notes)
                .padding(.bottom)
            Text("Current State:").font(.headline)
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
