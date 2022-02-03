//
//  AddApartmentView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/30/22.
//

import SwiftUI

struct AddApartmentView: View {
    @State private var url: String = ""
    @State private var notes = ""
    @State private var currentState: ApartmentState = .interested
    @State private var updatingState = LoadingState<Bool>.notStarted
    @CurrentUserState var user
    @EnvironmentObject var apartmentSearch: ApartmentSearch
    @Environment(\.back_dismiss) var dismiss
    private var apartmentAddingState: Binding<ApartmentAddingState> {
        Binding(get: {
            switch currentState {
            case .interested, .uninterested, .opinions(_):
                return .interested
            case .unsure:
                return .unsure
            case .reachedOutToBroker:
                return .reachedOutToBroker
            case .seeing(_):
                return .seeing
            }
        }, set: { (val: ApartmentAddingState) in
            switch val {
            case .interested, .all, .uninterested, .opinion:
                self.currentState = .interested
            case .unsure:
                self.currentState = .unsure
            case .reachedOutToBroker:
                self.currentState = .reachedOutToBroker
            case .seeing:
                self.currentState = .seeing(date: Date().addingTimeInterval(60 * 60 * 24))
            }
            
        })
    }
    
    var body: some View {
        switch updatingState {
        case .notStarted:
            Form {
                TextField("Home URL", text: $url)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                Picker("Current State", selection: apartmentAddingState) {
                    ForEach(ApartmentAddingState.allCases, id: \.self) { option in
                        Text(option.rawValue)
                    }
                }
                switch currentState {
                case .seeing(let date):
                    DatePicker("When are you seeing the home?", selection: Binding(get: { date }, set: { self.currentState = .seeing(date: $0) }), in: Date()...)
                default:
                    EmptyView()
                }
                TextField("Notes", text: $notes)
                Button("Save Home") {
                    Task {
                        self.updatingState = .loading
                        do {
                            try await ApartmentAPIInteractor.addApartment(url: self.url, apartmentSearchId: self.apartmentSearch.id) {
                                ApartmentModel(location: $0, url: self.url, state: self.currentState, dateUploaded: Date(), author: user.id!, apartmentSearchId: self.apartmentSearch.id, notes: self.notes)
                            }
                            self.updatingState = .success(true)
                        } catch {
                            self.updatingState = .error(error.localizedDescription)
                        }
                    }
                }.disabled(URL(string: url) == nil || notes.isEmpty)
            }
        case .loading:
            ProgressView("Uploading")
        case .success(_):
            Text("Success!")
                .foregroundColor(.green)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
        case .error(let str):
            Text("Something went wrong, edit again. \(str)").onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.updatingState = .notStarted
                }
            }
        }
    }
}
