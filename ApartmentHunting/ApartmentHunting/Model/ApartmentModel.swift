//
//  ApartmentModel.swift
//  Apartments
//
//  Created by Jack Rosen on 1/22/22.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import LinkPresentation
import SwiftUI

enum ApartmentState: Codable, Equatable {
    case interested
    case unsure
    case uninterested
    case reachedOutToBroker
    case seeing(date: Date)
    case opinions(opinions: [Opinion])
}

struct Opinion: Codable, Equatable {
    var totalRating: Double
    var author: String
    var authorId: String
    var pros: [ProCon]
    var cons: [ProCon]
}

struct ProCon: Codable, Equatable, Identifiable {
    let id: String
    var reason: String
    var importance: Double
}

struct ApartmentModel: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let location: String
    let url: String
    var state: ApartmentState
    let dateUploaded: Date
    let author: String?
    var previousStates: [ApartmentState]?
    let apartmentSearchId: String
    let notes: String
}
