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
    @State var offset: CGSize = .zero
    func getScaleAmount() -> CGFloat {              // scale
        let maxWidth = UIScreen.main.bounds.width / 2
        let currentAmount = abs(offset.width)
        let percentage = currentAmount / maxWidth
        return 1.0 - min(percentage, 0.5) * 0.5
    }
    func getRotationAmount() -> CGFloat {       // rotate
        let maxWidth = UIScreen.main.bounds.width / 2
        let currentAmount = offset.width
        let percentage = Double(currentAmount / maxWidth)
        return percentage * 10
    }
    private var likeButton: some View {             // like button
        Button(action: {
            
        }, label: {
            HStack {
                Spacer()
                Image(systemName: "hand.thumbsup.fill")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .padding()
            .background(Color.blue)
            .frame(width: 64, height: 64, alignment: .center)
            .cornerRadius(32)
            .shadow(radius: 20)
        })
    }
    private var imageFrame: some View {             // image frame
        RoundedRectangle(cornerRadius: 20)
            .frame(width: 300, height: 500)
            .offset(offset)
            .scaleEffect(getScaleAmount())
            .rotationEffect(Angle(degrees: getRotationAmount()))
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        withAnimation(.spring()) {
                            offset = value.translation
                        }
                    })
                    .onEnded({ value in
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                }))
    }
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                ForEach(vm.allImages) { classImage in
                    CardView(card: classImage).padding(8)
                }
            }
            Spacer()
            likeButton
            Spacer()
        }
    }
}

struct ImageSwipeView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSyncView()
    }
}
