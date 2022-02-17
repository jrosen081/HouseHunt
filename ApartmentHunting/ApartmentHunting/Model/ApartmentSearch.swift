//
//  ApartmentSearch.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/28/22.
//

import Foundation
import FirebaseFirestoreSwift

struct ApartmentSearchDTO: Codable {
    @DocumentID var id: String?
    let name: String
    var users: [String]
    var requests: [String]
    var entryCode: String
    var brokerResponse: String?
    var acceptedHouse: String?
}

extension ApartmentSearchDTO {
    init(search: ApartmentSearch) {
        self = ApartmentSearchDTO(id: search.id, name: search.name, users: search.users.compactMap(\.id), requests: search.requests.compactMap(\.id), entryCode: search.entryCode, brokerResponse: search.brokerResponse, acceptedHouse: acceptedHouse)
    }
}

class ApartmentSearch: ObservableObject, Equatable {
    static func == (lhs: ApartmentSearch, rhs: ApartmentSearch) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.users == rhs.users && lhs.requests == rhs.requests && lhs.entryCode == rhs.entryCode && lhs.acceptedHouse == rhs.acceptedHouse
    }
    
    let id: String
    let name: String
    @Published var users: [User]
    @Published var requests: [User]
    let entryCode: String
    @Published var brokerResponse: String?
    @Published var acceptedHouse: ApartmentModel?
    
    init(id: String, name: String, users: [User], requests: [User], entryCode: String, brokerResponse: String?, acceptedHouse: ApartmentModel?) {
        self.id = id
        self.name = name
        self.users = users
        self.requests = requests
        self.entryCode = entryCode
        self.brokerResponse = brokerResponse
        self.acceptedHouse = acceptedHouse
    }
}
