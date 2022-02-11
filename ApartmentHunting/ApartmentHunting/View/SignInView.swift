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
    
    @ViewBuilder
    private var mainView: some View {
        VStack {
            Text("Home Hunt")
                .font(.largeTitle)
                .padding()
            VStack(alignment: .leading, spacing: 2) {
                TextFieldEntry(title: "Email", text: $email)
                    .padding(.bottom)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                TextFieldEntry(title: "Password", text: $password, isSecure: true)
                    .textContentType(signInState == .login ? .password : .newPassword)
                    .padding(.bottom)
                switch signInState {
                case .login:
                    EmptyView()
                case .createUser(let name):
                    let binding: Binding<String> = Binding(get: {name}, set: { self.signInState = .createUser(name: $0) })
                    TextFieldEntry(title: "Name", text: binding)
                        .textContentType(.name)
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
                switch signInState {
                case .login:
                    authInteractor.signIn(email: email, password: password)
                case .createUser(let name):
                    authInteractor.createUser(email: email, password: password, name: name)
                }
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
