//
//  ChatLogView.swift
//  Sync
//
//  Created by Renhao Xue on 1/15/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct ChatMessage: Identifiable {
    var id: String { documentID }
    let documentID: String
    let fromID, toID, text: String
    init(documentID: String, data: [String: Any]) {
        self.documentID = documentID
        self.fromID = data["fromID"] as? String ?? ""
        self.toID = data["toID"] as? String ?? ""
        self.text = data["text"] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var chatMessages = [ChatMessage]()
    let chatUser: ChatUser?
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessages()
    }
    private func fetchMessages() {
        guard let fromID = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toID = chatUser?.uid else {return}
        FirebaseManager.shared.firestore.collection("messages").document(fromID).collection(toID).order(by: "timestamp").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("failed to listen for message: \(error)")
                return
            }
            querySnapshot?.documentChanges.forEach({ change in
                if change.type == .added {
                    let data = change.document.data()
                    let ID = change.document.documentID
                    self.chatMessages.append(.init(documentID: ID, data: data))
                }
            })
        }
    }
    func handleSend() {
        print(chatText)
        guard let fromID = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toID = chatUser?.uid else {return}
        let document = FirebaseManager.shared.firestore.collection("messages").document(fromID).collection(toID).document()
        let messageData = ["fromID": fromID, "toID": toID, "text": self.chatText, "timestamp": Timestamp()] as [String : Any]
        document.setData(messageData) { error in
            if let error = error {
                print("failed to send data1 to firestore: \(error)")
            }
        }
        let recipientDocument = FirebaseManager.shared.firestore.collection("messages").document(toID).collection(fromID).document()
        recipientDocument.setData(messageData) { error in
            if let error = error {
                print("failed to send data2 to firestore: \(error)")
            }
        }
        
    }
}

struct ChatLogView: View {
    let chatUser: ChatUser?
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    @ObservedObject var vm: ChatLogViewModel
    private var chatBottomBar: some View {      // text editor and send button
        HStack(spacing: 4) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 20))
            Text(vm.chatText.isEmpty ? "Sync now..." : vm.chatText)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .foregroundColor(Color.gray)
                .opacity(vm.chatText.isEmpty ? 1 : 0)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        .padding(.horizontal, 12)
                )
                .overlay(
                    TextEditor(text: $vm.chatText)
                        .font(.body)
                        .foregroundColor(Color(.label))
                        .multilineTextAlignment(.leading)
                        .cornerRadius(12)
                        .padding(.horizontal, 12)
                        .opacity(vm.chatText.isEmpty ? 0.6 : 1)
                )
            Button {
                vm.handleSend()
                vm.chatText = ""
            } label: {
                Text("Send").font(.system(size: 18, weight: .semibold))
            }

        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    private var messageView: some View {    // msg log
        ScrollView {
            ForEach(vm.chatMessages) { message in
                HStack {
                    if message.fromID == FirebaseManager.shared.auth.currentUser?.uid {
                        HStack {
                            Spacer()
                            HStack {
                                Text(message.text)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    } else {
                        HStack {
                            HStack {
                                Text(message.text)
                                    .foregroundColor(.black)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
            }
            HStack{Spacer()}
        }
        .background(Color(UIColor.systemGray5))
        .safeAreaInset(edge: .bottom) {
            chatBottomBar
                .background(.ultraThinMaterial)
                .onAppear {
                    UIScrollView.appearance().keyboardDismissMode = .onDrag
                }
        }
    }
    var body: some View {
        VStack {
            messageView
                .onAppear {
                    UIScrollView.appearance().keyboardDismissMode = .onDrag
                }
        }
        .toolbar {      // for name and pfp
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Text(chatUser?.email ?? "")
                    WebImage(url: URL(string: chatUser?.profileImageUrl ?? ""))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipped()
                        .cornerRadius(36)
                        .overlay(RoundedRectangle(cornerRadius: 55).stroke(Color(.label), lineWidth: 1))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatLogView(chatUser: .init(data: ["uid": "SUOfGXztVYQz5ruV1N1mnnwSHo93", "email": "lukasxue2023@gmail.com", "profileImageUrl": "https://firebasestorage.googleapis.com:443/v0/b/sync-e63f3.appspot.com/o/SUOfGXztVYQz5ruV1N1mnnwSHo93?alt=media&token=d8b934fc-b129-4f7e-929d-c88ab08217d1"]))
        }
    }
}