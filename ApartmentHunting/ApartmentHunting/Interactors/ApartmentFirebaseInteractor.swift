//
//  ApartmentAPIInteractor.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import LinkPresentation
import SwiftUI

struct ApartmentFirebaseInteractor {
    static let allCharacters = [
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "0","1","2","3","4","5","6","7","8","9","!","@","#","$","%","^","&","*","-","_","+","=","?",">","<","?"
    ]
    private enum Constants {
        static let dateUploadedName = "dateUploaded"
        static let apartmentsKey = "apartments"
    }
    private static let database = Firestore.firestore()
    
    private static func apartmentsCollection(for id: String) -> CollectionReference {
        database.collection(Constants.apartmentsKey).document(id).collection(Constants.apartmentsKey)
    }
    static func getApartments(id: String) async throws -> [ApartmentModel] {
        return try await apartmentsCollection(for: id).order(by: Constants.dateUploadedName, descending: true).getDocuments().documents.compactMap {
            return try? $0.data(as: ApartmentModel.self)
        }
    }
    
    static func addApartment(url: String, apartmentSearchId: String, creator: (String) -> ApartmentModel) async throws {
        guard let linkUrl = URL(string: url) else { throw NSError(domain: "no", code: 100, userInfo: [NSLocalizedDescriptionKey: "You need to specify a valid URL"]) }
        let metadata = try await LPMetadataProvider().startFetchingMetadata(for: linkUrl)
        let model = creator(metadata.title ?? "Home")
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let _ = try apartmentsCollection(for: apartmentSearchId).addDocument(from: model, completion: { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                })
            } catch {
                continuation.resume(throwing: error)
            }
            
        }
        
    }
    
    static func update(apartment: ApartmentModel) {
        try? apartmentsCollection(for: apartment.apartmentSearchId).document(apartment.id!).setData(from: apartment)
    }
    
    static func listenForChanges(apartment: Binding<ApartmentModel>) -> ListenerRegistration {
        apartmentsCollection(for: apartment.wrappedValue.apartmentSearchId)
            .document(apartment.wrappedValue.id!).addSnapshotListener { snapshot, error in
                do {
                    if let snapshotReal = snapshot, let model = try snapshotReal.data(as: ApartmentModel.self) {
                        apartment.wrappedValue = model
                    }
                } catch {
                    print(error)
                }
            }
    }
    
    static func listenForChanges(apartmentSearch: Binding<ApartmentSearch>, authInteractor: AuthInteractor) -> ListenerRegistration {
        self.database.collection("apartments").document(apartmentSearch.wrappedValue.id).addSnapshotListener { snapshot, error in
            Task {
                do {
                    if let snapshotReal = snapshot, let dto = try snapshotReal.data(as: ApartmentSearchDTO.self) {
                        let model = try await search(fromDTO: dto, authInteractor: authInteractor)
                        await MainActor.run {
                            apartmentSearch.wrappedValue = model
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    static func addApartmentSearch(searchCreator: (String) -> ApartmentSearchDTO) -> String {
        let code = (0..<8).map { _ in Self.allCharacters.randomElement()! }.joined()
        return try! self.database.collection(Constants.apartmentsKey).addDocument(from: searchCreator(code)).documentID
    }
    
    static func requestApartment(currentUser: User, id: String) async throws -> (id: String, name: String) {
        guard var apartment = try await self.database.collection(Constants.apartmentsKey).whereField("entryCode", isEqualTo: id).getDocuments().documents.first?.data(as: ApartmentSearchDTO.self) else {
            throw NSError(domain: "100", code: 200, userInfo: [NSLocalizedDescriptionKey: "No Home Search with that code"])
        }
        apartment.requests.append(currentUser.id!)
        try self.database.collection(Constants.apartmentsKey).document(apartment.id!).setData(from: apartment)
        return (apartment.id!, apartment.name)
    }
    
    static func removeApartmentRequest(id: String, currentUser: User, authInteractor: AuthInteractor) async throws {
        let search = try await getApartmentSearch(id: id, authInteractor: authInteractor)
        search.requests.removeAll(where: { $0.id == currentUser.id })
        let user = User(id: currentUser.id, apartmentSearchState: .noRequest, name: currentUser.name)
        try? self.database.collection(Constants.apartmentsKey).document(search.id).setData(from: ApartmentSearchDTO(search: search))
        authInteractor.update(user: user)
    }
    
    static func getApartmentSearch(id: String, authInteractor: AuthInteractor) async throws -> ApartmentSearch {
        guard let collection = try await self.database.collection(Constants.apartmentsKey).document(id).getDocument().data(as: ApartmentSearchDTO.self) else {
            throw NSError(domain: "", code: 100, userInfo: [NSLocalizedDescriptionKey: "No Home Search Found"])
        }
        return try await search(fromDTO: collection, authInteractor: authInteractor)
    }
    
    private static func search(fromDTO collection: ApartmentSearchDTO, authInteractor: AuthInteractor) async throws -> ApartmentSearch {
        var newUsers = [User]()
        for user in collection.users {
            try await newUsers.append(authInteractor.fetchUser(id: user))
        }
        var newRequests = [User]()
        for user in collection.requests {
            try await newRequests.append(authInteractor.fetchUser(id: user))
        }
        var acceptedHouse: ApartmentModel? = nil
        do {
            if let acceptedId = collection.acceptedHouse {
                acceptedHouse = try await self.apartmentsCollection(for: collection.id!).document(acceptedId).getDocument().data(as: ApartmentModel.self)
            }
        } catch {
            print(error)
        }
        return ApartmentSearch(id: collection.id!, name: collection.name, users: newUsers, requests: newRequests, entryCode: collection.entryCode, brokerResponse: collection.brokerResponse, acceptedHouse: acceptedHouse)
    }
    
    static func acceptUser(apartmentSearch: ApartmentSearch, user: User, authInteractor: AuthInteractor) {
        apartmentSearch.requests.removeAll(where: { $0.id == user.id })
        apartmentSearch.users.append(user)
        let newUser = User(id: user.id, apartmentSearchState: .success(id: apartmentSearch.id), name: user.name)
        try? self.database.collection(Constants.apartmentsKey).document(apartmentSearch.id).setData(from: ApartmentSearchDTO(search: apartmentSearch))
        authInteractor.update(user: newUser)
    }
    
    static func rejectUser(apartmentSearch: ApartmentSearch, user: User, authInteractor: AuthInteractor) {
        apartmentSearch.requests.removeAll(where: { $0.id == user.id })
        apartmentSearch.users.removeAll(where: { $0.id == user.id })
        let newUser = User(id: user.id, apartmentSearchState: .noRequest, name: user.name)
        try? self.database.collection(Constants.apartmentsKey).document(apartmentSearch.id).setData(from: ApartmentSearchDTO(search: apartmentSearch))
        authInteractor.update(user: newUser)
    }
    
    static func updateBrokerComment(apartmentSearch: ApartmentSearch, comment: String) {
        apartmentSearch.brokerResponse = comment
        try? self.database.collection(Constants.apartmentsKey).document(apartmentSearch.id).setData(from: ApartmentSearchDTO(search: apartmentSearch))
    }
    
    static func setSelectedHouse(apartmentSearch: ApartmentSearch, houseId: String) {
        var dto = ApartmentSearchDTO(search: apartmentSearch)
        dto.acceptedHouse = houseId
        try? self.database.collection(Constants.apartmentsKey).document(apartmentSearch.id).setData(from: dto)
    }
}
