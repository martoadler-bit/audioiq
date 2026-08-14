import SwiftUI

struct SplashView: View {
    var body: some View {
        GeometryReader { geo in
            Image("HeroBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .background(DS.background)
    }
}
