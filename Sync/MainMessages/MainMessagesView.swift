//
//  MainMessagesView.swift
//  Sync
//
//  Created by Renhao Xue on 1/13/22.
//

import SwiftUI

struct ChatUser {
    let uid, email, profileImageUrl: String
}

class MainMessageViewModel: ObservableObject {
    @Published var user: ChatUser?
    private func fetchCurrentUser() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        FirebaseManager.shared.firestore.collection("user").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch current user: \(error)")
                return
            }
            guard let data = snapshot?.data() else {return}
            self.user = ChatUser(uid: data["uid"] as? String ?? "",
                                email: data["email"] as? String ?? "",
                                profileImageUrl: data["profileImageUrl"] as? String ?? "")
        }
    }
    init() {
        fetchCurrentUser()
    }
}

struct MainMessagesView: View {
    
    @ObservedObject private var vm = MainMessageViewModel()
    @State var logOutOption = false
    private var NavigationBar: some View {      // nav bar
        HStack {
            Image(systemName: "person.fill")
                .font(.system(size: 34, weight: .heavy))
            VStack(alignment: .leading, spacing: 4) {
                Text("USERNAME")
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
                logOutOption.toggle()   // FIXME: LOG OUT OPTION
            }, label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .thin))
            })
        }
        .padding()
    }
    private var newMessageButton: some View {       // create msg
        Button(action: {
            
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
    }
    private var messageView: some View {            // msg queue
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
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
