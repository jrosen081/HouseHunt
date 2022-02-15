//
//  LinkInteractor.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/2/22.
//

import Foundation
import LinkPresentation

@MainActor
class LinkInteractor: ObservableObject {
    private var cache: [URL: LPLinkMetadata] = [:]
    
    
    func fetchMetadata(url: URL) async throws -> LPLinkMetadata {
        if let cachedValue = self.cache[url] {
            return cachedValue
        }
        
        let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
        self.cache[url] = metadata
        return metadata
    }
}
