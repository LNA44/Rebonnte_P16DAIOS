import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLogInLoading = false
    @State private var isSignUpLoading = false
   // @EnvironmentObject var session: SessionViewModel
    @ObservedObject var loginVM: LoginViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .accessibilityHint("Enter your email address")
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .accessibilityHint("Enter your password")
            
            Button(action: {
                isLogInLoading = true
                loginVM.signIn(email: email, password: password) {
                    isLogInLoading = false
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    
                    if isLogInLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                            .accessibilityLabel("Logging in")
                            .accessibilityHint("Please wait while we log you in")
                    } else {
                        Text("Login")
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .bold()
                    }
                }
            }
            .disabled(isLogInLoading || isSignUpLoading)
            .accessibilityLabel("Login")
            .accessibilityHint("Tap to log in with your email and password")
            .accessibilityAddTraits(.isButton)
            
            Button(action: {
                isSignUpLoading = true
                loginVM.signUp(email: email, password: password) {
                    isSignUpLoading = false
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    
                    if isSignUpLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                            .accessibilityLabel("Signing up")
                            .accessibilityHint("Please wait while we create your account")
                    } else {
                        Text("SignUp")
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .bold()
                    }
                }
            }
            .disabled(isLogInLoading || isSignUpLoading)
            .accessibilityLabel("Sign up")
            .accessibilityHint("Tap to create a new account")
            .accessibilityAddTraits(.isButton)
        }
        .hideKeyboardOnTap() 
        .padding()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(loginVM: LoginViewModel(sessionVM: SessionViewModel())).environmentObject(SessionViewModel())
    }
}
