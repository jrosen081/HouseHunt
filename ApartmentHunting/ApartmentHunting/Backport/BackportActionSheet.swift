//
//  BackportActionSheet.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 2/10/22.
//

import SwiftUI


protocol ActionSheetButton {
    static func `default`(message: Text, action: (() -> Void)?) -> ActionSheetButton
    static func destructive(message: Text, action: (() -> Void)?) -> ActionSheetButton
    static func cancel() -> ActionSheetButton
}

#if !os(macOS)
extension ActionSheet.Button: ActionSheetButton {
    static func `default`(message: Text, action: (() -> Void)?) -> ActionSheetButton {
        return self.default(message, action: action)
    }
    
    static func destructive(message: Text, action: (() -> Void)?) -> ActionSheetButton {
        return self.destructive(message, action: action)
    }
    
    static func cancel() -> ActionSheetButton {
        return self.cancel(nil)
    }
}
#endif

extension Alert.Button: ActionSheetButton {
    static func `default`(message: Text, action: (() -> Void)?) -> ActionSheetButton {
        Alert.Button.default(message, action: action)
    }
    
    static func destructive(message: Text, action: (() -> Void)?) -> ActionSheetButton {
        Alert.Button.destructive(message, action: action)
    }
    
    static func cancel() -> ActionSheetButton {
        Alert.Button.cancel(nil)
    }
    
    
}

@available(iOS 15, macOS 12, *)
extension Button: ActionSheetButton where Label == Text {
    static func `default`(message: Text, action: (() -> Void)?) -> ActionSheetButton {
        return Button(action: { action?() }, label: { message })
    }
    
    static func destructive(message: Text, action: (() -> Void)?) -> ActionSheetButton {
        return Button(role: .destructive, action: { action?() }, label: { message })
    }
    
    static func cancel() -> ActionSheetButton {
        return Button(role: .cancel, action: {  }, label: { Text("Cancel") })
    }
}

extension View {
    @ViewBuilder
    func back_confirmationDialog(isPresented: Binding<Bool>, title: Text, creator: (ActionSheetButton.Type) -> [ActionSheetButton]) -> some View {
        if #available(iOS 15, macOS 12, *) {
            confirmationDialog(title, isPresented: isPresented, titleVisibility: .visible) {
                let values = creator(Button<Text>.self).map { $0 as! Button<Text> }
                ForEach(values.indices, id: \.self) { index in
                    values[index]
                }
            }
        } else {
            #if !os(macOS)
            actionSheet(isPresented: isPresented) {
                ActionSheet(title: title, message: nil, buttons: creator(ActionSheet.Button.self).map { $0 as! ActionSheet.Button })
            }
            #else
            alert(isPresented: isPresented) {
                let buttons = creator(Alert.Button.self).map { $0 as! Alert.Button }
                return Alert(title: title, message: nil, primaryButton: buttons[0], secondaryButton: buttons[1])
            }
            #endif
        }
    }
}
