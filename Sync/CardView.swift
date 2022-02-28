//
//  CardView.swift
//  Sync
//
//  Created by Lukas Xue on 2/27/22.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI

struct CardView: View {
    let card: imageModel
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
    func getOpacity() -> CGFloat {
        let maxWidth = UIScreen.main.bounds.width / 2
        let currentAmount = abs(offset.width)
        let percentage = Double(currentAmount / maxWidth)
        return 1 - percentage
    }
    var body: some View {
        ZStack {
            WebImage(url: URL(string: self.card.imageUrl)).resizable()
                .cornerRadius(12)
                .scaledToFit()
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
                                switch value.translation.width {
                                case (-200)...(200):
                                    offset = .zero
                                case let x where x > 200:
                                    offset.width = 800
                                case let x where x < -200:
                                    offset.width = -800
                                default: offset = .zero
                                }
                            }
                    }))
                .zIndex(1)
            RoundedRectangle(cornerRadius: 12)
                .frame(alignment: .center)
                .background(.ultraThinMaterial)
                .opacity(getOpacity())
            VStack(alignment: .leading) {
                Spacer()
                WebImage(url: URL(string: self.card.userImageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipped()
                    .cornerRadius(36)
                    .overlay(RoundedRectangle(cornerRadius: 55).stroke(Color(.label), lineWidth: 1))
                Text(self.card.userEmail)
            }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(card: .init(documentID: "3B1JTMWRdojEKW4cXw3q", data: ["imageUrl": "https://firebasestorage.googleapis.com:443/v0/b/sync-e63f3.appspot.com/o/hY42rOfpqJScIgDF899S7MOzpaE20?alt=media&token=bc93a850-f41e-4fb2-9e6e-43ebccdebd4b",
                                                                      "timestamp": "February 27, 2022 at 2:02:44 AM UTC-5",
                                                                        "uid":"hY42rOfpqJScIgDF899S7MOzpaE2"]))
    }
}
