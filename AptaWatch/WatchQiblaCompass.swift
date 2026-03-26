import SwiftUI

struct WatchQiblaCompass: View, Animatable {
    var heading: Double
    let qiblaDirection: Double

    var animatableData: Double {
        get { heading }
        set { heading = newValue }
    }

    var body: some View {
        Canvas { ctx, size in
            let cx  = size.width / 2
            let cy  = size.height / 2
            let r: CGFloat = min(cx, cy) - 2   // outer radius

            // ── Bezel tick ring — rotates with heading so N always tracks geographic north ──
            for step in 0 ..< 72 {                         // every 5°
                let deg      = Double(step * 5)
                let screenRad = (deg - heading) * .pi / 180 - .pi / 2
                let ca = cos(screenRad), sa = sin(screenRad)

                let isCardinal  = step % 18 == 0           // 0, 90, 180, 270
                let isMajor     = step %  6 == 0           // every 30°
                let isMedium    = step %  2 == 0           // every 10°

                let tickLen: CGFloat = isCardinal ? 7 : isMajor ? 5 : isMedium ? 3.5 : 2
                let alpha: Double    = isCardinal ? 0.8    : isMedium ? 0.45 : 0.22
                let width: CGFloat   = isCardinal ? 1.2    : 0.6

                let outerPt = CGPoint(x: cx + r * ca,             y: cy + r * sa)
                let innerPt = CGPoint(x: cx + (r - tickLen) * ca, y: cy + (r - tickLen) * sa)

                ctx.stroke(
                    Path { p in p.move(to: innerPt); p.addLine(to: outerPt) },
                    with: .color(WatchThemeColors.tertiaryTextColor().opacity(alpha)),
                    lineWidth: width
                )

                // Cardinal labels
                if isCardinal {
                    let labels = ["N", "E", "S", "W"]
                    let label  = labels[step / 18]
                    let lPt    = CGPoint(x: cx + (r - 13) * ca, y: cy + (r - 13) * sa)
                    let isN    = step == 0
                    let t = Text(label)
                        .font(.system(size: 7, weight: isN ? .semibold : .regular))
                        .foregroundColor(WatchThemeColors.secondaryTextColor().opacity(isN ? 1.0 : 0.55))
                    ctx.draw(ctx.resolve(t), at: lPt)
                }
            }

            // ── Qibla chevron — rides the bezel at the Qibla bearing ──────
            // Tip points inward; when it aligns with the 12 o'clock mark the user faces Mecca.
            let qRad  = (qiblaDirection - heading) * .pi / 180 - .pi / 2
            let qCos  = cos(qRad), qSin = sin(qRad)
            let qpCos = cos(qRad + .pi / 2), qpSin = sin(qRad + .pi / 2)   // perpendicular

            let tipR: CGFloat  = r - 9      // inward tip
            let baseR: CGFloat = r - 3      // wide base near ring
            let spread: CGFloat = 4.5

            let chevTip = CGPoint(x: cx + tipR  * qCos,                    y: cy + tipR  * qSin)
            let chevL   = CGPoint(x: cx + baseR * qCos + spread * qpCos,   y: cy + baseR * qSin + spread * qpSin)
            let chevR   = CGPoint(x: cx + baseR * qCos - spread * qpCos,   y: cy + baseR * qSin - spread * qpSin)

            ctx.stroke(
                Path { p in p.move(to: chevL); p.addLine(to: chevTip); p.addLine(to: chevR) },
                with: .color(WatchThemeColors.textColor()),
                lineWidth: 1.8
            )

            // ── Fixed 12 o'clock chevron (your current facing direction) ──
            // Smaller and dimmer so it doesn't compete with the Qibla chevron.
            let notch: CGFloat = 3.5
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: cx - notch, y: cy - r + notch * 1.8))
                    p.addLine(to: CGPoint(x: cx, y: cy - r + 1.5))
                    p.addLine(to: CGPoint(x: cx + notch, y: cy - r + notch * 1.8))
                },
                with: .color(WatchThemeColors.secondaryTextColor().opacity(0.55)),
                lineWidth: 1
            )
        }
        .frame(width: 88, height: 88)
    }
}
