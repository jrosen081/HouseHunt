// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Home Hunting
  internal static let appName = L10n.tr("AppStrings", "App Name")
  /// Dismiss
  internal static let dismiss = L10n.tr("AppStrings", "Dismiss")
  /// Show Profile
  internal static let showProfile = L10n.tr("AppStrings", "ShowProfile")
  /// Something went wrong: %@
  internal static func somethingWentWrong(_ p1: Any) -> String {
    return L10n.tr("AppStrings", "SomethingWentWrong", String(describing: p1))
  }

  internal enum LoginPage {
    /// Email
    internal static let emailTextField = L10n.tr("AppStrings", "LoginPage.emailTextField")
    /// Go to Log In
    internal static let goToLogin = L10n.tr("AppStrings", "LoginPage.goToLogin")
    /// Go to Sign In
    internal static let goToSignIn = L10n.tr("AppStrings", "LoginPage.goToSignIn")
    /// Logging In
    internal static let loggingIn = L10n.tr("AppStrings", "LoginPage.loggingIn")
    /// Log In
    internal static let logInButton = L10n.tr("AppStrings", "LoginPage.logInButton")
    /// Name
    internal static let nameTextField = L10n.tr("AppStrings", "LoginPage.nameTextField")
    /// Password
    internal static let passwordTextField = L10n.tr("AppStrings", "LoginPage.passwordTextField")
    /// Sign In
    internal static let signInButton = L10n.tr("AppStrings", "LoginPage.signInButton")
    /// Signing In
    internal static let signingIn = L10n.tr("AppStrings", "LoginPage.signingIn")
  }

  internal enum WaitingView {
    /// Profile
    internal static let profile = L10n.tr("AppStrings", "WaitingView.profile")
    /// Remove Request
    internal static let removeRequestButton = L10n.tr("AppStrings", "WaitingView.removeRequestButton")
    /// Search Name
    internal static let searchName = L10n.tr("AppStrings", "WaitingView.searchName")
    /// Waiting on Response
    internal static let waitingOnResponse = L10n.tr("AppStrings", "WaitingView.waitingOnResponse")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
