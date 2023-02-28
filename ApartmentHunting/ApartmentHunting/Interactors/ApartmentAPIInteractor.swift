//
//  ApartmentAPIInteractor.swift
//  HomeHunt
//
//  Created by Jack Rosen on 2/19/23.
//

import Foundation
import FirebaseAuth

struct ApartmentAPIInteractor {
    private enum APIError: Error {
        case badStatusCode(expected: Int, actual: Int)
        case badRequest
    }
    
    static func createUser(name: String) async throws {
        struct CreateUserRequest: Codable {
            let name: String
        }
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/user/create",
                                                body: CreateUserRequest(name: name),
                                                type: "POST") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 204)
    }
    
    static func updateBrokerComment(apartmentSearch: ApartmentSearch, comment: String) async throws {
        struct UpdateBrokerRequest: Codable {
            let text: String
        }
        
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/home-search/\(apartmentSearch.id)/broker",
                                                body: UpdateBrokerRequest(text: comment),
                                                type: "PUT") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 204)
        apartmentSearch.brokerResponse = comment
    }
    
    static func setSelectedHouse(apartmentSearch: ApartmentSearch, houseId: String) async throws {
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/home-search/\(apartmentSearch.id)/select?selectedId=\(houseId)",
                                                body: Optional<Data>.none,
                                                type: "POST") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 204)
    }
    
    static func addToken(token: String) async throws {
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/user/token?token=\(token)",
                                                body: Optional<Data>.none,
                                                type: "POST") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 204)
    }
    
    static func removeToken(token: String) async throws {
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/user/token?token=\(token)",
                                                body: Optional<Data>.none,
                                                type: "DELETE") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 204)
    }
    
    static func requestApartment(code: String) async throws {
        struct RequestApartmentBody: Codable {
            let code: String
        }
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/home-search/join",
                                                body: RequestApartmentBody(code: code),
                                                type: "PUT") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 204)
    }
    
    
    static func rejectUser(user: User) async throws {
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/home-search/\(user.id!)/reject",
                                                body: Optional<Double>.none,
                                                type: "DELETE") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 200)
    }
    
    static func acceptUser(user: User) async throws {
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/home-search/\(user.id!)/accept",
                                                body: Optional<Double>.none,
                                                type: "PUT") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 200)
    }
    
    static func leaveApartmentSearch() async throws {
        guard let urlRequest = createURLRequest(url: "http://localhost:8080/home-search/leave",
                                                body: Optional<Double>.none,
                                                type: "DELETE") else {
            throw APIError.badRequest
        }
        let _ = try await performRequest(urlRequest: urlRequest, expectedResponse: 204)

    }
    
    private static func createURLRequest<Body: Codable>(url: String, body: Body?, type: String) -> URLRequest? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        if let body, let optionalBody = try? JSONEncoder().encode(body) {
            request.httpBody = optionalBody
        }
        request.httpMethod = type
        return request
    }
    
    private static func performRequest(urlRequest: URLRequest, expectedResponse: Int) async throws -> Data {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else { throw APIError.badRequest }
        var urlRequest = urlRequest
        urlRequest.addValue(token, forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let httpResponse = response as! HTTPURLResponse
        guard httpResponse.statusCode == expectedResponse else {
            throw APIError.badStatusCode(expected: expectedResponse,
                                         actual: httpResponse.statusCode)
        }
        return data
    }
}
