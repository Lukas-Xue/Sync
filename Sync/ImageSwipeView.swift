//
//  ImageSwipeView.swift
//  Sync
//
//  Created by Renhao Xue on 1/19/22.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI


class ImageSwipeViewModel: ObservableObject {
    @Published var allImages = [imageModel]()
    var imageClass: String?
    init(imageClass: String?) {
        self.imageClass = imageClass
    }
    func fetchImages() {        // fetch all images under that class
        print(self.imageClass ?? "")
        if ((imageClass ?? "").isEmpty) {
            return
        }
        FirebaseManager.shared.firestore.collection("class").document(imageClass ?? "").collection("image").getDocuments { documentSnapshot, error in
            if let error = error {
                print("failed to fetch all images: \(error)")
                return
            }
            for snapshot in documentSnapshot!.documents {
                guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
                let ID = snapshot.documentID
                let data = imageModel(documentID: ID, data: snapshot.data())
                guard uid != data.uid else { continue }
                self.allImages.append(.init(documentID: ID, data: snapshot.data()))
            }
        }
    }
}

struct ImageSwipeView: View {
    @ObservedObject var vm: ImageSwipeViewModel
//    private var likeButton: some View {             // like button
//        Button(action: {
//
//        }, label: {
//            HStack {
//                Spacer()
//                Image(systemName: "hand.thumbsup.fill")
//                    .font(.system(size: 24, weight: .bold))
//                Spacer()
//            }
//            .foregroundColor(.white)
//            .padding(.vertical)
//            .padding()
//            .background(Color.blue)
//            .frame(width: 64, height: 64, alignment: .center)
//            .cornerRadius(32)
//            .shadow(radius: 20)
//        })
//    }
    var body: some View {
        VStack {
            ZStack {
                ForEach(vm.allImages) { classImage in
                    CardView(card: classImage).padding(12)
                }
            }
            Spacer()
        }
        .navigationBarTitle("", displayMode: .inline)
    }
}

struct ImageSwipeView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSyncView()
    }
}
