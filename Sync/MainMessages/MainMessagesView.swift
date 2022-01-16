//
//  MainMessagesView.swift
//  Sync
//
//  Created by Renhao Xue on 1/13/22.
//

import SwiftUI
import SDWebImageSwiftUI

class MainMessageViewModel: ObservableObject {
    @Published var user: ChatUser?
    @Published var isLoggedOut: Bool = true
    func fetchCurrentUser() {       // get user information
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user: \(error)")
                return
            }
            guard let data = snapshot?.data() else {return}
            self.user = .init(data: data)
        }
    }
    init() {
        DispatchQueue.main.async {
            self.isLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
    }
    func handleSignOut() {      // go back to login view
        isLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}

struct MainMessagesView: View {
    
    @ObservedObject private var vm = MainMessageViewModel()
    @State var shouldShowNewMessageScreen = false
    @State var chatUser: ChatUser?
    @State var shouldOpenChatLogView = false
    private var NavigationBar: some View {      // nav bar
        HStack {
            WebImage(url: URL(string: vm.user?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 50).stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(vm.user?.email ?? "")")
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 12))
                        .foregroundColor(Color(UIColor.lightGray))
                }
            }
            Spacer()
            Button(action: {
                vm.handleSignOut() // FIXME: LOG OUT OPTION
            }, label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .thin))
            })
        }
        .padding()
        .fullScreenCover(isPresented: $vm.isLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLogin: {
                self.vm.isLoggedOut = false
                self.vm.fetchCurrentUser()
            })
        }
    }
    private var newMessageButton: some View {       // create msg
        Button(action: {
            shouldShowNewMessageScreen.toggle()
        }, label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        })
            .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
                CreateNewMessageView(didSelectNewUser: { user in
                    self.chatUser = user
                    self.shouldOpenChatLogView.toggle()
                })
            }
    }
    private var messageView: some View {            // msg queue
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    NavigationLink {
                        Text("Destination")
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .padding(8)
                                .overlay(RoundedRectangle(cornerRadius: 44).stroke(Color(.label), lineWidth: 1))
                            VStack(alignment: .leading) {
                                Text("Username")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Message sent to user")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(UIColor.lightGray))
                            }
                            Spacer()
                            Text("22d")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    Divider()
                        .padding(.vertical, 8)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationBar
                messageView
                
                NavigationLink("", isActive: $shouldOpenChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            .overlay(newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView().preferredColorScheme(.dark)
    }
}
