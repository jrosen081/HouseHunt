//
//  CurrentUser.swift.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/28/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

enum UserApartmentState: Codable, Equatable {
    case noRequest
    case requested(name: String, id: String)
    case success(id: String)
}

struct User: Codable, Equatable, Identifiable {
    @DocumentID var id: String?
    var apartmentSearchState: UserApartmentState
    let name: String
}
