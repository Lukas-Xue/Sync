//
//  RecentMessage.swift
//  Sync
//
//  Created by Renhao Xue on 1/18/22.
//

import Foundation
import Firebase

struct RecentMessage: Identifiable {
    var id: String {documentID}
    let documentID: String
    let text, fromID, toID: String
    let timestamp: Timestamp
    init(documentID: String, data: [String: Any]) {
        self.documentID = documentID
        self.text = data["text"] as? String ?? ""
        self.fromID = data["fromID"] as? String ?? ""
        self.toID = data["toID"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
    }
}
