//
//  LoginTouchBar.swift
//  Home Hunt (macOS)
//
//  Created by Jack Rosen on 2/18/22.
//

import AppKit
import SwiftUI

// SHIM NOT WORKING, need to set up listeners within the app, same for `Commands`
extension NSTouchBarItem.Identifier {
    static let loginButton = NSTouchBarItem.Identifier.init(rawValue: "Login_Button")
}

class LoginTouchBarController: NSViewController, NSTouchBarDelegate {
    var currentValue: SignInView.SignInState
    var onSubmit: () -> Void
    
    override func loadView() {
        self.view = NSView()
    }
    
    init(currentValue: SignInView.SignInState, onSubmit: @escaping () -> Void) {
        self.currentValue = currentValue
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func makeTouchBar() -> NSTouchBar? {
        let bar = NSTouchBar()
        bar.delegate = self
        bar.principalItemIdentifier = .loginButton
        bar.defaultItemIdentifiers = [.loginButton]
        return bar
    }
    
    @objc func submit() {
        self.onSubmit()
    }
    
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if identifier == .loginButton {
            let button = NSButtonTouchBarItem(identifier: identifier, title: currentValue.touchBarTitle, target: self, action: #selector(self.submit))
            return button
        }
        return nil
    }
}

struct LoginTouchBarAdapter: NSViewControllerRepresentable {
    let currentValue: SignInView.SignInState
    let onSubmit: () -> Void
    func makeNSViewController(context: Context) -> LoginTouchBarController {
        return LoginTouchBarController(currentValue: currentValue, onSubmit: onSubmit)
    }
    
    func updateNSViewController(_ nsViewController: LoginTouchBarController, context: Context) {
        nsViewController.currentValue = currentValue
        nsViewController.onSubmit = onSubmit
    }
}
