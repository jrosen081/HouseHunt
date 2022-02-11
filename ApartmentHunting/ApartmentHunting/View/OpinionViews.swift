//
//  OpinionViews.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/30/22.
//

import SwiftUI

struct ProConView: View {
    @Binding var pro: ProCon
    let isPro: Bool
    let isEditable: Bool
    
    var body: some View {
        if isEditable {
            VStack {
                TextField("What did you \(isPro ? "like" : "dislike")?", text: $pro.reason)
                Stepper("Importance: \(String(format: "%.1f", pro.importance))", value: $pro.importance, in: 0.0...10, step: 0.5)
            }
        } else {
            VStack(alignment: .leading) {
                Text(pro.reason)
                Text("Importance: ") + Text("\(String(format: "%.1f", pro.importance))").bold()
            }.multilineTextAlignment(.leading)
        }
    }
}

struct OpinionView: View {
    @Binding var opinion: Opinion
    let onFinish: (Opinion) -> ()
    let isEditable: Bool
    
    var body: some View {
        List {
            if !isEditable {
                HStack {
                    Text("Overall Rating:")
                    Spacer()
                    Text("\(String(format: "%.1f", opinion.totalRating))")
                }
            } else {
                Stepper("Overall Rating: \(String(format: "%.1f", opinion.totalRating))", value: $opinion.totalRating, in: 0.0...10, step: 0.5)
            }
            
            Section(header: Text("Pros")) {
                ForEach($opinion.pros) { $pro in
                    ProConView(pro: $pro, isPro: true, isEditable: isEditable)
                }
                if isEditable {
                    Button(action: {
                        self.opinion.pros.append(ProCon(id: UUID().uuidString, reason: "", importance: 5.0))
                    }) {
                        Text("Add Pro")
                    }
                }
            }
            Section(header: Text("Cons")) {
                ForEach($opinion.cons) { $pro in
                    ProConView(pro: $pro, isPro: false, isEditable: isEditable)
                }
                if isEditable {
                    Button(action: {
                        self.opinion.cons.append(ProCon(id: UUID().uuidString, reason: "", importance: 5.0))
                    }) {
                        Text("Add Con")
                    }
                }
            }.navigationTitle(isEditable ? "Add Opinion" : "\(opinion.author)'s Opinion")
        }.toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditable {
                    Button(action: {
                        onFinish(opinion)
                    }) {
                        Text("Add")
                    }
                }
            }
        }
    }
}

struct AddOpinionView: View {
    @State private var opinion = Opinion(totalRating: 5, author: "Hi", authorId: "", pros: [], cons: [])
    @Environment(\.back_dismiss) var dismiss
    @CurrentUserState var user
    let isEditable: Bool
    let onFinish: (Opinion) -> ()
    var body: some View {
        OpinionView(opinion: $opinion, onFinish: {
            dismiss()
            var finishedOpinion = $0
            finishedOpinion.pros.removeAll(where: { $0.reason.isEmpty })
            finishedOpinion.cons.removeAll(where: { $0.reason.isEmpty })
            onFinish(finishedOpinion)
        }, isEditable: isEditable)
        .onAppear {
            opinion.author = user.name
            opinion.authorId = user.id!
        }
    }
}
