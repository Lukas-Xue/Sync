//
//  ImageSwipeView.swift
//  Sync
//
//  Created by Renhao Xue on 1/19/22.
//

import SwiftUI
import Firebase

struct ImageSwipeView: View {
    @State var offset: CGSize = .zero
    let imageClass: String
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
            Text(self.imageClass)
            imageFrame
            Spacer()
            likeButton
            Spacer()
        }
    }
}

struct ImageSwipeView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSwipeView(imageClass: "desktop computer")
    }
}
