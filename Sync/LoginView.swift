//
//  ContentView.swift
//  Sync
//
//  Created by Renhao Xue on 1/12/22.
//

import SwiftUI
import Firebase

struct LoginView: View {
    
    let didCompleteLogin: () -> ()
    @State private var isLogin = false                  // changing mode
    @State private var email: String = ""       // Email Address
    @State private var password: String = ""    // Password
    @State private var signInError = ""                 // signin/signup error
    @State private var shouldShowImagePicker = false    // show image picker
    @State var image: UIImage?
    
    var areBothFieldFilled: Bool {  // for changing sign in button style
        return !email.isEmpty && !password.isEmpty
    }
    private func handleAction() {   // handle signIn/signUp action
        if isLogin {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    private func loginUser() {          // log in
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                signInError = "Fail to sign in: \(error)"
                return
            }
            self.didCompleteLogin()
        }
    }
    private func createNewAccount() {   // create acc
        if self.image == nil {
            self.signInError = "please select an avatar image and try again"
            return
        }
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                signInError = "Failed to create user: \(error)"
                return
            }
            signInError = "Success"
            self.persistImageToStorage()
            self.didCompleteLogin()
        }
    }
    private func persistImageToStorage() {      // save image to storage and save user information
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.1) else {return}
        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.signInError = "Failed to push image to cloud: \(error)"
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    self.signInError = "Failed to retrieve downloadURL: \(error)"
                    return
                }
                
                guard let url = url else {return}
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    private func storeUserInformation(imageProfileUrl: URL) {       // save user information to firestore
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users").document(uid).setData(userData) { error in
            if let error = error {
                self.signInError = "Firestore error: \(error)"
                return
            }
            print("Success")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("**Think** with Clarity")
                    .font(.system(size: 24))
                Text("__Sync__ with Infinity")
                    .font(.system(size: 24))
                Picker(selection: $isLogin, label: Text("Picker Here")) {   // picker
                    Text("Sign in")
                        .tag(true)
                    Text("Sign up")
                        .tag(false)
                }
                .cornerRadius(8)
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if !isLogin {   // select a pfp
                    Button(action: {
                        shouldShowImagePicker.toggle()
                    }, label: {
                        
                        VStack {    // pfp
                            if let image = self.image {    // if seletected
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 128, height: 128)
                                    .cornerRadius(64)
                            } else {
                                Image(systemName: "person") // if not, use default
                                    .font(.system(size: 64))
                                    .padding()
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.blue, lineWidth: 3))
                    })
                        .padding()
                }
                
                HStack {    // Email address
                    Image(systemName: "envelope")
                    Spacer()
                    TextField("Email Address", text: $email)
                        .padding()
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .background(Color(UIColor.systemGray5))
                        .frame(maxWidth: 300, alignment: .trailing)
                        .cornerRadius(12)
                }
                .padding(8)
                
                HStack {        // Password
                    Image(systemName: "key")
                    Spacer()
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(UIColor.systemGray5))
                        .frame(maxWidth: 300, alignment: .trailing)
                        .cornerRadius(12)
                }
                .padding(8)
                
                Button(action: {    // Sign in Button
                    handleAction()
                }, label: {
                    Text(isLogin ? "Sign In" : "Sign Up")
                        .foregroundColor(Color.white)
                        .frame(width: 370, height: 50, alignment: .center)
                        .background(areBothFieldFilled ? Color.blue : Color.gray)
                        .cornerRadius(12)
                        .disabled(areBothFieldFilled)
                })
                    .padding(12)
                Text(signInError)   // Error msg
                    .foregroundColor(.red)
                Spacer()
            }
            .padding()
            .navigationBarTitle("")
            .navigationBarHidden(true)
            Spacer()
        }
        .background(Color(.init(white: 0, alpha: 0.05))
                        .ignoresSafeArea())
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLogin: {
            
        })
    }
}
