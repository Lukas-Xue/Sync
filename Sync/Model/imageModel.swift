//
//  imageModel.swift
//  Sync
//
//  Created by Lukas Xue on 2/26/22.
//

import Foundation
import Firebase

struct imageModel: Identifiable {
    var id: String {documentID}
    let documentID: String
    let imageUrl, uid: String
    let timestamp: Timestamp
    init(documentID: String, data: [String: Any]) {
        self.documentID = documentID
        self.imageUrl = data["imageUrl"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.uid = data["uid"] as? String ?? ""
    }
}
