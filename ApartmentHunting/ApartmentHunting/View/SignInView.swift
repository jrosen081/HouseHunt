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
            Text(L10n.appName)
                .font(.largeTitle)
                .padding()
            #if os(macOS)
                .focusable()
            #endif
            VStack(alignment: .leading, spacing: 2) {
                TextFieldEntry(title: L10n.LoginPage.emailTextField, text: $email)
                    .padding(.bottom)
                #if !os(macOS)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                #endif
                TextFieldEntry(title: L10n.LoginPage.passwordTextField, text: $password, isSecure: true)
                #if !os(macOS)
                    .textContentType(signInState == .login ? .password : .newPassword)
                #endif
                    .padding(.bottom)
                switch signInState {
                case .login:
                    EmptyView()
                case .createUser(let name):
                    let binding: Binding<String> = Binding(get: {name}, set: { self.signInState = .createUser(name: $0) })
                    TextFieldEntry(title: L10n.LoginPage.nameTextField, text: binding)
                    #if !os(macOS)
                        .textContentType(.name)
                    #endif
                        .padding(.bottom)
                }
            }.frame(maxWidth: .infinity)
            switch authInteractor.authState {
            case .error(let error):
                Text(L10n.somethingWentWrong(error))
                    .foregroundColor(.red)
            default:
                EmptyView()
            }
            Spacer()
            RoundedButton(title: signInState == .login ? L10n.LoginPage.logInButton : L10n.LoginPage.signInButton, color: .green) {
                signIn()
            }
            RoundedButton(title: signInState == .login ? L10n.LoginPage.goToSignIn : L10n.LoginPage.goToLogin, color: .primary) {
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
    }
    
    var body: some View {
        ZStack {
            mainView
            switch authInteractor.authState {
            case .loading:
                Group {
                    Color.black.opacity(0.4).ignoresSafeArea(.all, edges: .all)
                    ProgressView(signInState == .login ? L10n.LoginPage.loggingIn : L10n.LoginPage.signingIn)
                        .padding(.vertical)
                }.animation(.easeInOut, value: authInteractor.authState)
            default:
                EmptyView()
            }
        }
    }
}
