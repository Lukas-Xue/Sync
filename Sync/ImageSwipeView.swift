//
//  ImageSwipeView.swift
//  Sync
//
//  Created by Renhao Xue on 1/19/22.
//

import SwiftUI

struct ImageSwipeView: View {
    @State var offset: CGSize = .zero
    func getScaleAmount() -> CGFloat {
        let maxWidth = UIScreen.main.bounds.width / 2
        let currentAmount = abs(offset.width)
        let percentage = currentAmount / maxWidth
        return 1.0 - min(percentage, 0.5) * 0.5
    }
    func getRotationAmount() -> CGFloat {
        let maxWidth = UIScreen.main.bounds.width / 2
        let currentAmount = offset.width
        let percentage = Double(currentAmount / maxWidth)
        return percentage * 10
    }
    var body: some View {
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
}

struct ImageSwipeView_Previews: PreviewProvider {
    static var previews: some View {
        ImageSwipeView()
    }
}
