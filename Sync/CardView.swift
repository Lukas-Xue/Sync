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
    @State var shouldOpenProfilePage = false
    var profilePageViewModel = ProfilePageViewModel(UserProfile: nil)
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
                .opacity(getOpacity())
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
                                    offset.width = 1300
                                case let x where x < -200:
                                    offset.width = -1300
                                default: offset = .zero
                                }
                            }
                    }))
                .zIndex(1)
            HStack {
                VStack(alignment: .leading) {
                    Spacer()
                    Button {
                        shouldOpenProfilePage.toggle()
                        self.profilePageViewModel.UserProfile = .init(data:
                                                                ["uid": card.uid,
                                                                 "email": card.userEmail,
                                                                 "profileImageUrl": card.userImageUrl])
                        self.profilePageViewModel.fetchAllImages()
                    } label: {
                        WebImage(url: URL(string: self.card.userImageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(60)
                            .overlay(RoundedRectangle(cornerRadius: 60).stroke(Color(.label), lineWidth: 1))
                    }
                    Text(self.card.userEmail)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .padding(8)
                        .background(.ultraThinMaterial)
                    NavigationLink("", isActive: $shouldOpenProfilePage) {
                        ProfilePageView(vm: self.profilePageViewModel)
                    }
                }
                .padding(.bottom, 60)
                .padding(.leading, 30)
                .opacity(getOpacity())
                Spacer()
            }
            .zIndex(2)
            RoundedRectangle(cornerRadius: 12)
                .frame(alignment: .center)
                .foregroundColor(.white)
                .opacity(getOpacity())
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
