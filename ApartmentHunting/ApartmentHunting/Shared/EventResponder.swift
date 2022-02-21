//
//  EventResponder.swift
//  HomeHunt
//
//  Created by Jack Rosen on 2/19/22.
//

import Foundation

enum Event {
    case sidebar
}

protocol EventResponder: AnyObject {
    func responds(to: Event) -> Bool
    func respond(to: Event)
}
