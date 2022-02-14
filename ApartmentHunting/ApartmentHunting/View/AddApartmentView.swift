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
    let onFinish: () -> Void
    
    private func performFinish() {
        #if !os(macOS)
        dismiss()
        #endif
        onFinish()
    }
    private var apartmentAddingState: Binding<ApartmentAddingState> {
        Binding(get: {
            switch currentState {
            case .interested, .uninterested, .opinions(_), .selected:
                return .interested
            case .unsure:
                return .unsure
            case .reachedOutToBroker:
                return .reachedOutToBroker
            case .seeing(_):
                return .seeing
            }
        }, set: { val in
            switch val {
            case .interested, .all, .uninterested, .opinion, .selected:
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
    
    @ViewBuilder
    var mainView: some View {
        switch updatingState {
        case .notStarted:
            TextFieldEntry(title: "Link to Listing", text: $url)
            #if !os(macOS)
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)
            #endif
                .padding(.bottom)
            HStack {
                Text("Current Step in Process")
                    .font(.subheadline).bold()
                Spacer()
                Picker("", selection: apartmentAddingState) {
                    ForEach(ApartmentAddingState.allCases, id: \.self) { option in
                        Text(option.rawValue)
                    }
                }
            }
            #if os(macOS)
            .pickerStyle(.radioGroup)
            #endif
            
            switch currentState {
            case .seeing(let date):
                Text("When are you seeing the home?")
                    .font(.subheadline)
                    .bold()
                DatePicker("When are you seeing the home?",
                           selection: Binding(get: { date }, set: { self.currentState = .seeing(date: $0) }),
                           in: Date()...).labelsHidden()
            default:
                EmptyView()
            }
            TextArea(title: "Notes", text: $notes)
            Spacer()
            RoundedButton(title: "Save Home", color: .green) {
                Task {
                    self.updatingState = .loading
                    do {
                        try await ApartmentAPIInteractor.addApartment(url: self.url,
                                                                      apartmentSearchId: self.apartmentSearch.id) {
                            ApartmentModel(location: $0,
                                           url: self.url,
                                           state: self.currentState,
                                           dateUploaded: Date(),
                                           author: user.id!,
                                           apartmentSearchId: self.apartmentSearch.id,
                                           notes: self.notes)
                        }
                        self.updatingState = .success(true)
                    } catch {
                        self.updatingState = .error(error.localizedDescription)
                    }
                }
            }
            .padding(.top)
            .disabled(URL(string: url) == nil || notes.isEmpty)
        case .loading:
            ProgressView("Uploading")
        case .success(_):
            Text("Success!")
                .foregroundColor(.green)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        performFinish()
                    }
                }
        case .error(_):
            ErrorView {
                self.updatingState = .notStarted
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            mainView
        }
        .padding()
        .toolbar {
            ToolbarItem {
                Button(action: {
                    performFinish()
                }) {
                    Text("Cancel")
                }
            }
        }
        .removingKeyboardOnTap()
    }
}
