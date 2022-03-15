//
//  AddBrokerInformationView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/10/22.
//

import SwiftUI

struct AddBrokerInformationView: View {
    @Environment(\.back_dismiss) var dismiss
    @KeyboardOpenState private var isFocused
    @State private var brokerInfo = ""
    let save: (String) -> Void
    var body: some View {
            VStack(alignment: .leading) {
                TextArea(title: "Hunt Information", text: $brokerInfo)
                Group {
                    if !isFocused {
                        Text("Use this space to write a default message about your Home Search to send to realtors.")
                        
                            .font(.caption).multilineTextAlignment(.leading)
                            .accessibilitySortPriority(1)
                    } else {
                        EmptyView()
                    }
                }.animation(.default, value: isFocused).transition(.opacity)
                Spacer()
                RoundedButton(title: "Save Information", color: .green) {
                    dismiss()
                    save(brokerInfo)
                }.disabled(brokerInfo.isEmpty)
            }
                .removingKeyboardOnTap()
        #if os(iOS)
                .analyticsScreen(name: "add_broker_informatioin")
        #endif
    }
}

struct AddBrokerInformationView_Previews: PreviewProvider {
    private struct Preview: View {
        @State private var showingView = false
        
        var body: some View {
            Button(action: { showingView.toggle() }) { Text("Show add View")}
            .sheet(isPresented: $showingView) {
                AddBrokerInformationView {_ in }
            }
        }
    }
    static var previews: some View {
        Preview()
    }
}
