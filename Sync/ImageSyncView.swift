//
//  ImageSyncView.swift
//  Sync
//
//  Created by Renhao Xue on 1/19/22.
//

import SwiftUI

struct ImageSyncView: View {
    @State private var buttonWidth: Double = UIScreen.main.bounds.width - 80
    @State private var buttonOffset: CGFloat = 0
    @State var shouldShowImagePicker = false
    @State var image: UIImage?
    let hapticFeedback = UINotificationFeedbackGenerator()
    private var slideButton: some View {    // bottom slide sync button, FIXME: on success
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
                                    
                                    // FIXME: CoreML + Persist Image to Firebase
                                    
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
                        .padding()
                }
            }
        }
    }
    var body: some View {
        VStack {
            Spacer()
            imagePickerButton
            Spacer()
            slideButton
                .frame(width: buttonWidth, height: 80, alignment: .center)
                .padding(.bottom, 40)
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
