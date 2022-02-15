//
//  AuthInteractor.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/28/22.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseMessaging

class AuthInteractor: ObservableObject {
    private enum Constants {
        static let userCollection = "users"
        static let tokensKey = "tokens"
    }
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    @Published var authState: LoadingState<User> = .notStarted
    private var shouldFetchUser = true
    private var stopListeningForUserChanges: (() -> Void)? = nil
    
    private var user: User? {
        switch self.authState {
        case .success(let user): return user
        default: return nil
        }
    }
    
    init() {
        createLocalUser()
    }
    
    public func fetchUser(id: String) async throws -> User {
        let document = try await firestore.collection(Constants.userCollection).document(id).getDocument()
        guard let user = try document.data(as: User.self) else {
            throw NSError(domain: "", code: 100, userInfo: [NSLocalizedDescriptionKey: "No user found with that id"])
        }
        return user
    }
    
    private func listenForChanges(id: String) {
        let listener = firestore.collection(Constants.userCollection).document(id).addSnapshotListener { document, error in
            guard let document = document else { return }
            do {
                guard let user = try document.data(as: User.self) else { return }
                self.authState = .success(user)
            } catch {
                print(error)
            }
        }
        self.stopListeningForUserChanges = {
            listener.remove()
        }
    }
    
    @MainActor
    private func fetchUserLocally(id: String) async {
        do {
            if shouldFetchUser {
                self.authState = try await .success(fetchUser(id: id))
            }
            self.listenForChanges(id: id)
        } catch {
            self.authState = .error(error.localizedDescription)
            try? self.auth.signOut()
        }
    }
    
    private func updateToken(token: String, userId: String, remove: Bool) {
        self.firestore.collection(Constants.userCollection).document(userId).setData([
            Constants.tokensKey: remove ? FieldValue.arrayRemove([token]) : FieldValue.arrayUnion([token])
        ], merge: true)
    }
    
    private func createLocalUser() {
        auth.addStateDidChangeListener { _, user in
            guard let user = user else {
                DispatchQueue.main.async {
                    self.authState = .notStarted
                }
                return
            }
            Task {
                await MainActor.run {
                    self.authState = .loading
                }
                await self.fetchUserLocally(id: user.uid)
            }
            if let token = Messaging.messaging().fcmToken {
                self.updateToken(token: token, userId: user.uid, remove: false)
            }
        }
    }
    
    func signIn(email: String, password: String) {
        self.authState = .loading
        Task {
            do {
                let _ = try await auth.signIn(withEmail: email, password: password)
            } catch {
                await MainActor.run {
                    self.authState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func createUser(email: String, password: String, name: String) {
        self.authState = .loading
        Task {
            do {
                self.shouldFetchUser = false
                let credential = try await auth.createUser(withEmail: email, password: password)
                let user = User(id: credential.user.uid, apartmentSearchState: .noRequest, name: name)
                try self.firestore.collection(Constants.userCollection).document(credential.user.uid).setData(from: user)
                self.shouldFetchUser = true
                await MainActor.run {
                    self.authState = .success(user)
                }
                
            } catch {
                self.shouldFetchUser = true
                await MainActor.run {
                    self.authState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func update(user: User) {
        let data: [String: Any] = ["apartmentSearchState": Optional<String>.none as Any]
        self.firestore.collection(Constants.userCollection).document(user.id!).updateData(data)
        try? self.firestore.collection(Constants.userCollection).document(user.id!).setData(from: user, merge: true)
        if self.user == nil || self.user?.id == user.id {
            DispatchQueue.main.async {
                self.authState = .success(user)
            }
        }
    }
    
    func signOut() {
        if let userId = user?.id, let token = Messaging.messaging().fcmToken {
            self.updateToken(token: token, userId: userId, remove: true)
        }
        self.stopListeningForUserChanges?()
        self.stopListeningForUserChanges = nil
        self.authState = .notStarted
        do {
            try self.auth.signOut()
        } catch {
            print(error)
        }
        
    }
}
