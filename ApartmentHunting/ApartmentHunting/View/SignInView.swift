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
    
    var body: some View {
        VStack {
            Text("Home Hunt")
                .font(.largeTitle)
                .padding()
            VStack(alignment: .leading) {
                Text("Email")
                TextField("Email", text: $email)
                    .padding(.bottom)
                    .textContentType(.emailAddress)
                Text("Password")
                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding(.bottom)
                switch signInState {
                case .login:
                    EmptyView()
                case .createUser(let name):
                    let binding: Binding<String> = Binding(get: {name}, set: { self.signInState = .createUser(name: $0) })
                    Text("Name")
                    TextField("Name", text: binding)
                        .textContentType(.name)
                        .padding(.bottom)
                }
            }.frame(maxWidth: .infinity).multilineTextAlignment(.leading)
            switch authInteractor.authState {
            case .loading:
                ProgressView(signInState == .login ? "Logging In" : "Signing Up")
                    .padding(.vertical)
            case .error(let error):
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
        }.frame(maxWidth: .infinity).padding().disabled(authInteractor.authState == .loading).textFieldStyle(.roundedBorder)
    }
}
