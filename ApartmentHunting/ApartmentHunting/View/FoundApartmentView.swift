//
//  FoundApartmentView.swift
//  HomeHunt
//
//  Created by Jack Rosen on 2/14/22.
//

import SwiftUI

struct FoundApartmentView: View {
    let apartmentModel: ApartmentModel
    @Binding var showingFindApartmentView: Bool
    var body: some View {
        VStack {
            Image(systemName: "house.fill")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 100)
            Text("Congratulations on selecting your new home!").font(.title2).bold()
            Spacer()
            Text(apartmentModel.location).font(.title3)
            Spacer()
            RoundedButton(title: "See Full Search", color: .green) {
                self.showingFindApartmentView = false
            }
        }.padding().navigationTitle("You did it!").toolbar {
            ToolbarItem {
                HStack { }
            }
        }
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
