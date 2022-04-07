//
//  ProfilePageView.swift
//  Sync
//
//  Created by Lukas Xue on 4/5/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

class ProfilePageViewModel: ObservableObject {
    @Published var UserProfile: ChatUser?
    @Published var allImages = [imageModel]()
    init(UserProfile: ChatUser?) {
        self.UserProfile = UserProfile
    }
    func fetchAllImages() {
        guard let uid = self.UserProfile?.uid else {return}
        FirebaseManager.shared.firestore.collection("user_image").document(uid).collection("images").getDocuments { documentSnapshot, error in
            if let error = error {
                print("failed to load user profile: \(error)")
                return
            }
            for snapShot in documentSnapshot!.documents {
                let ID = snapShot.documentID
                let data = imageModel(documentID: ID, data: snapShot.data())
                self.allImages.append(data)
            }
        }
    }
}

struct ProfilePageView: View {
    @ObservedObject var vm: ProfilePageViewModel
    @State var shouldOpenChatLogView = false
    var chatLogViewModel = ChatLogViewModel(chatUser: nil)
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    WebImage(url: URL(string: vm.UserProfile?.profileImageUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(80)
                        .overlay(RoundedRectangle(cornerRadius: 80).stroke(Color(.label), lineWidth: 1))
                        .padding(.leading, 30)
                        .padding(.top, 30)
                    Spacer()
                    VStack {
                        Spacer()
                        Button {
                            shouldOpenChatLogView.toggle()
                            self.chatLogViewModel.chatUser = vm.UserProfile
                            self.chatLogViewModel.fetchMessages()
                        } label: {
                            HStack {
                                Image(systemName: "message")
                                    .font(.system(size: 20))
                                Text("Message")
                                    .font(.system(size: 20))
                            }
                            .padding(.trailing, 30)
                            .cornerRadius(8)
                            .shadow(radius: 10)
                        }
                        Spacer()
                    }
                }
                HStack {
                    Text(vm.UserProfile?.email ?? "")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                        .padding(.leading, 30)
                    Spacer()
                }
            }
            .padding(.bottom, 10)
            ForEach(vm.allImages){ imagePost in
                VStack {
                    HStack {
                        VStack {
                            WebImage(url: URL(string: vm.UserProfile?.profileImageUrl ?? ""))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 42, height: 42)
                                .clipped()
                                .cornerRadius(42)
                                .overlay(RoundedRectangle(cornerRadius: 42).stroke(Color(.label), lineWidth: 0.5))
                                .shadow(radius: 15)
                                .padding(.top, 20)
                            Spacer()
                        }
                        .padding(.leading, 42)
                        Spacer()
                        WebImage(url: URL(string: imagePost.imageUrl))
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(20)
                            .shadow(radius: 10)
                        Spacer()
                    }
                    .frame(width: 400, height: 300, alignment: .center)
                    Divider()
                        .padding(.vertical, 8)
                }
            }
            NavigationLink("", isActive: $shouldOpenChatLogView) {
                ChatLogView(vm: chatLogViewModel)
            }
        }
    }
}

struct ProfilePageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
