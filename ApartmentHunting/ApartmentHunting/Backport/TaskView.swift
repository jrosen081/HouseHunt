//
//  TaskView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/27/22.
//

import SwiftUI

private struct TaskView<Content: View>: View {
    let child: Content
    let perform: () async -> Void
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        child.onAppear {
            guard task == nil else { return }
            task = Task {
                await perform()
            }
        }.onDisappear {
            task?.cancel()
            task = nil
        }
    }
}

extension View {
    @ViewBuilder
    func back_task(perform: @escaping () async -> Void) -> some View {
        if #available(iOS 15, macOS 12, *) {
            Group {
                if #available(iOS 15, macOS 12, *) {
                    self.task { await perform() }
                }
            }
        } else {
            TaskView(child: self, perform: perform)
        }
    }
}
