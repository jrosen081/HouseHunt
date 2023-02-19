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
    
    private static func createURLRequest<Body: Codable>(url: String, body: Body, type: String) -> URLRequest? {
        guard let url = URL(string: url), let body = try? JSONEncoder().encode(body) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpBody = body
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
