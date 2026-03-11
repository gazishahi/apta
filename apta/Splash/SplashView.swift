import SwiftUI

struct SplashView: View {
    enum SplashMode {
        case onboarding
        case logoOnly
    }

    let mode: SplashMode
    let onComplete: () -> Void

    @State private var letterOpacities: [Double] = [0, 0, 0, 0]
    @State private var letterOffsets: [CGFloat] = [-20, -20, -20, -20]
    @State private var suffixOpacities: [Double] = [0, 0, 0, 0]
    @State private var suffixOffsets: [CGFloat] = [-30, -30, -30, -30]
    @State private var overallOpacity: Double = 1.0

    private let letters = ["a", "p", "t", "a"]
    private let suffixes = ["nother", "rayer", "ime", "pp"]
    private let longestWord = "another"

    private func fittedFontSize(for width: CGFloat, height: CGFloat) -> CGFloat {
        let heightBased = height / 4.8
        // Binary search for the largest font size where "another" fits in availableWidth
        var lo: CGFloat = 1
        var hi: CGFloat = heightBased
        while hi - lo > 0.5 {
            let mid = (lo + hi) / 2
            let font = UIFont.systemFont(ofSize: mid, weight: .light)
            let textWidth = (longestWord as NSString).size(withAttributes: [.font: font]).width
            if textWidth <= width {
                lo = mid
            } else {
                hi = mid
            }
        }
        return lo
    }

    var body: some View {
        GeometryReader { geo in
            let availableHeight = geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom
            let horizontalPadding: CGFloat = 24
            let availableWidth = geo.size.width - horizontalPadding * 2
            let fontSize = fittedFontSize(for: availableWidth, height: availableHeight)

            ZStack {
                AptaColors.background.ignoresSafeArea()

                switch mode {
                case .onboarding:
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<4, id: \.self) { i in
                            HStack(spacing: 0) {
                                Text(letters[i])
                                    .opacity(letterOpacities[i])
                                    .offset(y: letterOffsets[i])

                                Text(suffixes[i])
                                    .opacity(suffixOpacities[i])
                                    .offset(x: suffixOffsets[i])
                            }
                            .font(.system(size: fontSize, weight: .light))
                            .foregroundStyle(AptaColors.primary)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .clipped()
                            .frame(height: availableHeight / 4)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                case .logoOnly:
                    let logoSize = min(availableWidth, availableHeight) * 0.28
                    Image("ChevronLogo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: logoSize, height: logoSize)
                }
            }
        }
        .opacity(overallOpacity)
        .onAppear {
            switch mode {
            case .onboarding:
                for i in 0..<4 {
                    let delay = Double(i) * AnimationConstants.splashLetterStagger
                    withAnimation(AnimationConstants.spring.delay(delay)) {
                        letterOpacities[i] = 1.0
                        letterOffsets[i] = 0
                    }
                }

                let suffixStartDelay = Double(3) * AnimationConstants.splashLetterStagger + 0.3
                for i in 0..<4 {
                    let delay = suffixStartDelay + Double(i) * AnimationConstants.splashWordStagger
                    withAnimation(AnimationConstants.spring.delay(delay)) {
                        suffixOpacities[i] = 1.0
                        suffixOffsets[i] = 0
                    }
                }

                withAnimation(.easeOut(duration: 0.4).delay(AnimationConstants.splashFadeOutDelay)) {
                    overallOpacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.splashTotalDuration) {
                    onComplete()
                }
            case .logoOnly:
                withAnimation(.easeOut(duration: 0.3).delay(AnimationConstants.splashLogoFadeOutDelay)) {
                    overallOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.splashLogoTotalDuration) {
                    onComplete()
                }
            }
        }
    }
}
