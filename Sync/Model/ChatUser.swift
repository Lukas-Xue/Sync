//
//  ChatUser.swift
//  Sync
//
//  Created by Renhao Xue on 1/14/22.
//

import Foundation

struct ChatUser: Identifiable {     // chat user model
    var id: String {uid}
    let uid, email, profileImageUrl: String
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
    }
}
