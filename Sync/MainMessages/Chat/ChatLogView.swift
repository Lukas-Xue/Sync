//
//  ChatLogView.swift
//  Sync
//
//  Created by Renhao Xue on 1/15/22.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct ChatMessage: Identifiable{
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
    @Published var Text = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var count = 0
    @Published var yourInfo: ChatUser?
    var firestoreListener: ListenerRegistration?
    var chatUser: ChatUser?
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessages()
    }
    func fetchMessages() {
        print("Event Listener Added Here, chat log view")
        guard let fromID = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toID = chatUser?.uid else {return}
        firestoreListener?.remove()
        chatMessages.removeAll()
        firestoreListener = FirebaseManager.shared.firestore.collection("messages").document(fromID).collection(toID).order(by: "timestamp").addSnapshotListener { querySnapshot, error in
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
            DispatchQueue.main.async {
                self.count += 1
            }
        }
    }
    func handleSend() {     // chat log into firestore
        guard let fromID = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toID = chatUser?.uid else {return}
        let document = FirebaseManager.shared.firestore.collection("messages").document(fromID).collection(toID).document()
        let messageData = ["fromID": fromID, "toID": toID, "text": self.chatText, "timestamp": Timestamp()] as [String : Any]
        document.setData(messageData) { error in
            if let error = error {
                print("failed to send data1 to firestore: \(error)")
            }
            self.persistRecentMessage()
        }
        let recipientDocument = FirebaseManager.shared.firestore.collection("messages").document(toID).collection(fromID).document()
        recipientDocument.setData(messageData) { error in
            if let error = error {
                print("failed to send data2 to firestore: \(error)")
            }
            self.count += 1
        }
    }
    private func persistRecentMessage() {       // recent messages into firestore
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        guard let toID = self.chatUser?.uid else {return}
        let document = FirebaseManager.shared.firestore.collection("recent_messages").document(uid).collection("messages").document(toID)
        let data = [
            "timestamp": Timestamp(),
            "text": self.chatText,
            "fromID": uid,
            "toID": toID,
            "profileImageUrl": chatUser?.profileImageUrl ?? "",
            "email": chatUser?.email ?? ""
        ] as [String : Any]
        document.setData(data) { error in
            if let error = error {
                print("Failed to save recent message: \(error)")
                return
            }
        }
        let receiverdocument = FirebaseManager.shared.firestore.collection("recent_messages").document(toID).collection("messages").document(uid)
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching your information: \(error)")
            }
            guard let yourdata = snapshot?.data() else {return}
            self.yourInfo = .init(data: yourdata)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let receiverdata = [
                "timestamp": Timestamp(),
                "text": self.chatText,
                "fromID": uid,
                "toID": toID,
                "profileImageUrl": self.yourInfo?.profileImageUrl ?? "",
                "email": self.yourInfo?.email ?? ""
            ] as [String : Any]
            receiverdocument.setData(receiverdata) { error in
                if let error = error {
                    print("Failed to save recent message for the other guy: \(error)")
                    return
                }
            }
            self.chatText = ""
        }
    }
}

struct ChatLogView: View {
    @FocusState private var isKeyboardOn: Bool
    @ObservedObject var vm: ChatLogViewModel
    private var chatBottomBar: some View {      // text editor and send button
        HStack(spacing: 4) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 20))
            Text(vm.Text.isEmpty ? "Sync now..." : vm.Text)
                .font(.body)
                .padding(.vertical, 8)
                .padding(.horizontal, 18)
                .foregroundColor(Color.gray)
                .opacity(vm.Text.isEmpty ? 1 : 0)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        .padding(.horizontal, 12)
                )
                .overlay(
                    TextEditor(text: $vm.Text)
                        .font(.body)
                        .foregroundColor(Color(.label))
                        .multilineTextAlignment(.leading)
                        .cornerRadius(12)
                        .padding(.horizontal, 12)
                        .opacity(vm.Text.isEmpty ? 0.6 : 1)
                        .focused($isKeyboardOn)
                        .onChange(of: isKeyboardOn, perform: { _ in
                            vm.count += 1
                        })
                )
            Button {
                vm.chatText = vm.Text
                vm.Text = ""
                vm.handleSend()
            } label: {
                Text("Send").font(.system(size: 18, weight: .semibold))
            }

        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    private var messageView: some View {    // msg log
        ScrollView {
            ScrollViewReader { ScrollViewProxy in
                ForEach(vm.chatMessages) { message in
                    HStack {    // blue or white message bubble
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
                .id("target")
                .onReceive(vm.$count) { _ in
                    withAnimation(.spring()) {
                        ScrollViewProxy.scrollTo("target", anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(UIColor.systemGray5))
        .safeAreaInset(edge: .bottom) {
            chatBottomBar
                .background(.ultraThinMaterial)
        }
    }
    @State var shouldOpenProfilePage = false
    var profilePageViewModel = ProfilePageViewModel(UserProfile: nil)
    var body: some View {
        VStack {
            messageView
                .onAppear {
                    UIScrollView.appearance().keyboardDismissMode = .onDrag
                }
            NavigationLink("", isActive: $shouldOpenProfilePage) {
                ProfilePageView(vm: self.profilePageViewModel)
            }
        }
        .toolbar {      // for name and pfp
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Text(vm.chatUser?.email ?? "")
                    Button {
                        self.profilePageViewModel.UserProfile = self.vm.chatUser
                        self.profilePageViewModel.allImages = [imageModel]()
                        self.profilePageViewModel.fetchAllImages()
                        self.shouldOpenProfilePage.toggle()
                    } label: {
                        WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipped()
                            .cornerRadius(36)
                            .overlay(RoundedRectangle(cornerRadius: 55).stroke(Color(.label), lineWidth: 1))
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
