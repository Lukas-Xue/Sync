//
//  ImageSyncView.swift
//  Sync
//
//  Created by Renhao Xue on 1/19/22.
//

import SwiftUI
import CoreML
import Firebase

struct ImageSyncView: View {
    @State private var buttonWidth: Double = UIScreen.main.bounds.width - 80
    @State private var buttonOffset: CGFloat = 0
    @State var shouldShowImagePicker = false
    @State var image: UIImage?
    @State var classification: String = ""
    @State var shouldShowImageSwipeView = false
    let model = try? MobileNetV2(configuration: MLModelConfiguration())
    let hapticFeedback = UINotificationFeedbackGenerator()
    private func performImageClassification() {
        let resizedImage = self.image?.resize(to: CGSize(width: 224, height: 224))
        let buffer = resizedImage?.pixelBuffer()
        let classification = try? self.model?.prediction(image: buffer!)
        if let classification = classification {
            self.classification = classification.classLabel
        }
    }
    private func persistImageToStorage() {      // put sync image into storage
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.25) else {return}
        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("failed to put sync image to cloud: \(error)")
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    print("failed to get sync image url: \(error)")
                    return
                }
                guard let url = url else {return}
                print(url)
                self.storeImageUnderUser(image: url)
                self.storeImageUnderClass(image: url)
            }
        }
    }
    private func storeImageUnderUser(image: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        let data = [
            "imageUrl": image.absoluteString,
            "uid": uid,
            "like": 0,
            "timestamp": Timestamp()
        ] as [String : Any]
        FirebaseManager.shared.firestore.collection("user_image").document(uid).collection("images").addDocument(data: data)
        print("Successfully put image under user collection")
    }
    private func storeImageUnderClass(image: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        let data = [
            "imageUrl": image.absoluteString,
            "uid": uid,
            "timestamp": Timestamp()
        ] as [String : Any]
        FirebaseManager.shared.firestore.collection("class").document(self.classification).collection("image").addDocument(data: data)
        print("Successfully put image under class collection")
    }
    private var slideButton: some View {    // FIXME: on success
        ZStack {
            // static background
            Capsule()
                .fill(Color.blue.opacity(0.2))
            Capsule()
                .fill(Color.blue.opacity(0.2))
                .padding(8)
            // call to action
            Text("Sync now...")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .offset(x:20)
            // capsule (dynamic)
            HStack {
                Capsule()
                    .fill(.blue)
                    .frame(width:buttonOffset+80)
                Spacer()
            }
            // draggable circle
            HStack {
                ZStack {
                    Circle()
                        .fill(.blue)
                    Circle()
                        .fill(.black.opacity(0.15))
                        .padding(8)
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 24, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80, alignment: .center)
                .offset(x: buttonOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if gesture.translation.width > 0 && buttonOffset <= buttonWidth - 80 {
                                buttonOffset = gesture.translation.width
                            }
                        }
                        .onEnded{ _ in
                            withAnimation(Animation.easeOut(duration: 0.3)){
                                if buttonOffset > 2 * buttonWidth / 3 {
                                    hapticFeedback.notificationOccurred(.success)
                                    buttonOffset = buttonWidth - 80
                                    if self.image == nil {      // did not pick image
                                        buttonOffset = 0
                                        self.classification = "select an Image!"
                                    } else {
                                        self.performImageClassification()
                                        buttonOffset = 0
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            self.persistImageToStorage()
                                        }
                                        shouldShowImageSwipeView.toggle()
                                    }
                                } else {
                                    buttonOffset = 0
                                }
                            }
                        }
                )
                Spacer()
            }
        }
    }
    private var imagePickerButton: some View {  // image picker button
        Button {
            shouldShowImagePicker.toggle()
        } label: {
            VStack {
                if let image = self.image {    // if seletected
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 40)
                        .padding(.vertical, 10)
                        .scaleEffect(x: 1+buttonOffset*0.0005, y: 1+buttonOffset*0.0005, anchor: .center)
                        .animation(.spring(), value: buttonOffset)
                } else {
                    Image(systemName: "photo") // if not, use default
                        .font(.system(size: 128))
                        .cornerRadius(20)
                        .padding()
                }
            }
        }
    }
    var body: some View {
        VStack {
            Text(classification)
            Spacer()
            imagePickerButton
            Spacer()
            slideButton
                .frame(width: buttonWidth, height: 80, alignment: .center)
                .padding(.bottom, 40)
//            NavigationLink("", isActive: $shouldShowImageSwipeView) {
//                ImageSwipeView()
//            }
        }
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
}

struct ImageSyncView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSyncView()
    }
}
