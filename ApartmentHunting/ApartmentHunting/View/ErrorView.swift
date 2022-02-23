//
//  ErrorView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/3/22.
//

import SwiftUI

struct ErrorView: View {
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .resizable()
                .aspectRatio(nil, contentMode: .fit)
                .frame(width: 50)
                .accessibilityHidden(true)
            Text("Something went wrong")
            Spacer()
            RoundedButton(title: "Retry", color: .primary) {
                retry()
            }
        }.foregroundColor(.red).padding()
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView {}
    }
}
