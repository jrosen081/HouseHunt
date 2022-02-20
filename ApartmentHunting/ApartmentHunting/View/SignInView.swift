//
//  SignInView.swift
//  ApartmentHunting
//
//  Created by Jack Rosen on 1/28/22.
//

import SwiftUI

struct SignInView: View {
    enum SignInState: Equatable {
        case login, createUser(name: String)
        var touchBarTitle: String {
            switch self {
            case .login:
                return "Log In"
            case .createUser(_):
                return "Create User"
            }
        }
    }
    @State private var email = ""
    @State private var password = ""
    @State private var signInState = SignInState.login
    @EnvironmentObject var authInteractor: AuthInteractor
    
    private func signIn() {
        switch signInState {
        case .login:
            authInteractor.signIn(email: email, password: password)
        case .createUser(let name):
            authInteractor.createUser(email: email, password: password, name: name)
        }
    }
    
    @ViewBuilder
    private var mainView: some View {
        VStack {
            Text("Home Hunting")
                .font(.largeTitle)
                .padding()
            #if os(macOS)
                .focusable()
            #endif
            VStack(alignment: .leading, spacing: 2) {
                TextFieldEntry(title: "Email", text: $email)
                    .padding(.bottom)
                #if !os(macOS)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                #endif
                TextFieldEntry(title: "Password", text: $password, isSecure: true)
                #if !os(macOS)
                    .textContentType(signInState == .login ? .password : .newPassword)
                #endif
                    .padding(.bottom)
                switch signInState {
                case .login:
                    EmptyView()
                case .createUser(let name):
                    let binding: Binding<String> = Binding(get: {name}, set: { self.signInState = .createUser(name: $0) })
                    TextFieldEntry(title: "Name", text: binding)
                    #if !os(macOS)
                        .textContentType(.name)
                    #endif
                        .padding(.bottom)
                }
            }.frame(maxWidth: .infinity)
            switch authInteractor.authState {            case .error(let error):
                Text("Something went wrong: \(error)")
                    .foregroundColor(.red)
            default:
                EmptyView()
            }
            Spacer()
            RoundedButton(title: signInState == .login ? "Log In" : "Sign Up", color: .green) {
                signIn()
            }
            RoundedButton(title: signInState == .login ? "Go to Sign Up" : "Go to Log In", color: .primary) {
                switch signInState {
                case .login:
                    self.signInState = .createUser(name: "")
                case .createUser(_):
                    self.signInState = .login
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .disabled(authInteractor.authState == .loading)
        .removingKeyboardOnTap()
        #if os(macOS)
        .background(LoginTouchBarAdapter(currentValue: self.signInState, onSubmit: signIn))
        #endif
    }
    
    var body: some View {
        ZStack {
            mainView
            switch authInteractor.authState {
            case .loading:
                Group {
                    Color.black.opacity(0.4).ignoresSafeArea(.all, edges: .all)
                    ProgressView(signInState == .login ? "Logging In" : "Signing Up")
                        .padding(.vertical)
                }.animation(.easeInOut, value: authInteractor.authState)
            default:
                EmptyView()
            }
        }
    }
}
