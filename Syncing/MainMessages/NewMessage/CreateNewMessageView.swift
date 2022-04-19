//
//  CreateNewMessageView.swift
//  Sync
//
//  Created by Renhao Xue on 1/14/22.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    @Published var users = [ChatUser]()     // list of users
    @Published var errorMessage = ""
    init() {
        fetchAllUsers()
    }
    private func fetchAllUsers() {      // get all user information
        FirebaseManager.shared.firestore.collection("users").getDocuments { documentSnapshot, error in
            if let error = error {
                print("Failed to fetch users: \(error)")
                self.errorMessage = "Failed to fetch users: \(error)"
                return
            }
            documentSnapshot?.documents.forEach({ snapshot in
                self.users.append(.init(data: snapshot.data()))
            })
            self.errorMessage = "Success"
        }
    }
}

struct CreateNewMessageView: View {
    let didSelectNewUser: (ChatUser) -> ()
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm = CreateNewMessageViewModel()
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(vm.users) { user in     // stack all the users
                    Button(action: {
                        didSelectNewUser(user)
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 55, height: 55)
                                .clipped()
                                .cornerRadius(55)
                                .overlay(RoundedRectangle(cornerRadius: 55).stroke(Color(.label), lineWidth: 1))
                            Text(user.email)
                                .foregroundColor(Color(.label))
                            Spacer()
                        }
                        .padding(.horizontal)
                        Divider().padding(.vertical, 8)
                    })
                }
            }.navigationTitle("New Message")
                .toolbar {      // cancel button
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button (action: {
                            presentationMode.wrappedValue.dismiss()
                        }, label: {
                            Text("Cancel")
                        })
                    }
                }
        }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
