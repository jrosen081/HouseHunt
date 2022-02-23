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
        ScrollView {
            VStack {
                Image(systemName: "house.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 100)
                    .accessibilityHidden(true)
                Text("Congratulations on selecting your new home!").font(.title2).bold()

                Text(apartmentModel.location).font(.title3).padding(.top)
                LinkView(linkUrl: URL(string: apartmentModel.url)).padding()
                Spacer()
            }.padding().navigationTitle("You did it!").toolbar {
                ToolbarItem {
                    Button("See Full Search") {
                        self.showingFindApartmentView = false
                    }
                }
            }.frame(maxWidth: .infinity)
        }
    }
}
