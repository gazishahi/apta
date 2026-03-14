import SwiftUI

struct QiblaStripCompass: View, Animatable {
    var heading: Double
    let qiblaDirection: Double
    @Environment(\.colorScheme) private var colorScheme

    var animatableData: Double {
        get { heading }
        set { heading = newValue }
    }

    private let stripWidth: CGFloat = 300
    private let degreesVisible: Double = 120
    private let tickSpacing: CGFloat = 2.5 // points per degree

    private var offset: Double {
        var diff = qiblaDirection - heading
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    private static let cardinals: [(Double, String)] = [
        (0, "N"), (45, "NE"), (90, "E"), (135, "SE"),
        (180, "S"), (225, "SW"), (270, "W"), (315, "NW")
    ]

    var body: some View {
        GeometryReader { geo in
            let center = geo.size.width / 2
            let pxPerDeg = geo.size.width / degreesVisible

            Canvas { context, size in
                let midY = size.height / 2

                // Draw tick marks across visible range
                let startDeg = heading - degreesVisible / 2
                let endDeg = heading + degreesVisible / 2

                let firstTick = Int(floor(startDeg))
                let lastTick = Int(ceil(endDeg))

                for deg in firstTick...lastTick {
                    let normalizedDeg = ((deg % 360) + 360) % 360
                    let offsetFromCenter = Double(deg) - heading
                    let x = center + CGFloat(offsetFromCenter) * pxPerDeg

                    if x < -10 || x > size.width + 10 { continue }

                    if normalizedDeg % 10 == 0 {
                        // Major tick
                        let tickHeight: CGFloat = normalizedDeg % 45 == 0 ? 14 : 10
                        let path = Path { p in
                            p.move(to: CGPoint(x: x, y: midY - tickHeight / 2))
                            p.addLine(to: CGPoint(x: x, y: midY + tickHeight / 2))
                        }
                          context.stroke(path, with: .color(ThemeColors.tertiaryTextColor(for: colorScheme)), lineWidth: normalizedDeg % 45 == 0 ? 1.5 : 0.8)

                        // Cardinal labels
                        if let cardinal = Self.cardinals.first(where: { Int($0.0) == normalizedDeg }) {
                            let text = Text(cardinal.1)
                                .font(.system(size: 10, weight: .medium))
                                  .foregroundColor(ThemeColors.secondaryTextColor(for: colorScheme))
                            context.draw(context.resolve(text), at: CGPoint(x: x, y: midY - 16))
                        }
                    } else if normalizedDeg % 5 == 0 {
                        // Minor tick
                        let path = Path { p in
                            p.move(to: CGPoint(x: x, y: midY - 3))
                            p.addLine(to: CGPoint(x: x, y: midY + 3))
                        }
                        context.stroke(path, with: .color(ThemeColors.quaternaryTextColor(for: colorScheme)), lineWidth: 0.5)
                    }
                }

                // Qibla marker
                let qiblaX = center + CGFloat(offset) * pxPerDeg
                if qiblaX > -20 && qiblaX < size.width + 20 {
                    // Triangle pointing down
                    let triangle = Path { p in
                        p.move(to: CGPoint(x: qiblaX, y: midY - 6))
                        p.addLine(to: CGPoint(x: qiblaX - 5, y: midY - 14))
                        p.addLine(to: CGPoint(x: qiblaX + 5, y: midY - 14))
                        p.closeSubpath()
                    }
                    context.fill(triangle, with: .color(ThemeColors.textColor(for: colorScheme)))

                    // Vertical line
                    let line = Path { p in
                        p.move(to: CGPoint(x: qiblaX, y: midY - 6))
                        p.addLine(to: CGPoint(x: qiblaX, y: midY + 10))
                    }
                    context.stroke(line, with: .color(ThemeColors.textColor(for: colorScheme)), lineWidth: 1.5)
                }

                // Center indicator (your heading)
                let centerLine = Path { p in
                    p.move(to: CGPoint(x: center, y: midY + 14))
                    p.addLine(to: CGPoint(x: center - 3, y: midY + 20))
                    p.addLine(to: CGPoint(x: center + 3, y: midY + 20))
                    p.closeSubpath()
                }
                context.fill(centerLine, with: .color(ThemeColors.tertiaryTextColor(for: colorScheme)))
            }
            // Fade edges
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.15),
                        .init(color: .black, location: 0.85),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .frame(height: 44)
    }
}
