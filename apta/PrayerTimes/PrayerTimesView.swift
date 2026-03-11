import SwiftUI
import CoreLocation

struct PrayerTimesView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel
    @ObservedObject var locationService: LocationService
    let onOpenSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var qiblaState: QiblaState = .idle
    @State private var lastTickDegree: Int = -999
    @State private var smoothedHeading: Double = 0
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var lastSelectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var dateChangeDirection: Int = 0
    @State private var showDatePicker = false
    @State private var wasAlignedWithQibla = false

    enum QiblaState: Equatable {
        case idle
        case searching
        case found
    }

    private var settings: PrayerSettings { PrayerSettings.current }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = settings.timeFormat == .twelve ? "h:mm" : "HH:mm"
        return f
    }

    private var amPmFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "a"
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private let qiblaThreshold: Double = 10.0

    private var qiblaOffset: Double? {
        guard let heading = locationService.heading else { return nil }
        var diff = viewModel.qiblaDirection - heading
        // Normalize to -180...180
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    var body: some View {
        ZStack {
            AptaColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    if !locationService.locationName.isEmpty {
                        Text(locationService.locationName.uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .kerning(1.5)
                            .foregroundStyle(AptaColors.tertiary)
                    }
                    Spacer()
                    Button {
                        Haptics.light()
                        onOpenSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(AptaColors.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Hijri date
                hijriNavigationRow
                    .padding(.bottom, 6)

                // Gregorian date (subtle, tappable via Hijri row)
                Text(dateFormatter.string(from: selectedDate).uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .kerning(1.2)
                    .foregroundStyle(AptaColors.tertiary)
                    .padding(.bottom, 20)

                Group {
                    if isToday {
                        VStack(spacing: 0) {
                            if let current = viewModel.currentPrayer {
                                VStack(spacing: 8) {
                                    Text(current.name.rawValue.uppercased())
                                        .font(Typography.currentPrayerName)
                                        .kerning(Typography.currentPrayerNameKerning)
                                        .foregroundStyle(AptaColors.secondary)

                                    currentTimeDisplay(for: current.time)

                                    Text(viewModel.countdown)
                                        .font(Typography.countdown)
                                        .foregroundStyle(AptaColors.tertiary)
                                }
                            }

                            Rectangle()
                                .fill(AptaColors.separator)
                                .frame(width: 40, height: 0.5)
                                .padding(.vertical, 32)

                            VStack(spacing: 0) {
                                ForEach(viewModel.upcomingPrayers) { prayer in
                                    HStack {
                                        Text(prayer.name.rawValue)
                                            .font(Typography.upcomingPrayerName)
                                            .foregroundStyle(AptaColors.primary)
                                        Spacer()
                                        upcomingTimeDisplay(for: prayer.time)
                                    }
                                    .padding(.horizontal, 48)
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                        .transition(contentTransition)
                    } else {
                        // Full day list
                        VStack(spacing: 0) {
                            ForEach(viewModel.prayers(for: selectedDate)) { prayer in
                                HStack {
                                    Text(prayer.name.rawValue)
                                        .font(Typography.upcomingPrayerName)
                                        .foregroundStyle(AptaColors.primary)
                                    Spacer()
                                    upcomingTimeDisplay(for: prayer.time)
                                }
                                .padding(.horizontal, 48)
                                .padding(.vertical, 10)
                            }
                        }
                        .transition(contentTransition)
                    }
                }
                .id(selectedDate)
                .animation(.easeInOut(duration: 0.3), value: selectedDate)
                .clipped()

                Spacer()

                // Qibla
                qiblaView
                    .padding(.bottom, 24)
            }

            if showDatePicker {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showDatePicker = false
                    }

                VStack(spacing: 0) {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding(20)

                    Button("Done") {
                        showDatePicker = false
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AptaColors.primary)
                    .padding(.bottom, 16)
                }
                .background(AptaColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 24)
                .transition(.scale(scale: 0.98).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDatePicker)
        .animation(AnimationConstants.prayerTransition, value: viewModel.currentPrayer?.name)
        .onChange(of: locationService.heading) {
            if let newHeading = locationService.heading {
                // Shortest-path interpolation across 0°/360° boundary
                var delta = newHeading - smoothedHeading
                while delta > 180 { delta -= 360 }
                while delta < -180 { delta += 360 }
                withAnimation(.easeOut(duration: 0.15)) {
                    smoothedHeading += delta
                }
            }
            guard (qiblaState == .searching || qiblaState == .found), let offset = qiblaOffset else { return }
            let isAligned = abs(offset) <= qiblaThreshold
            if isAligned && !wasAlignedWithQibla {
                Haptics.qiblaFound()
                withAnimation(AnimationConstants.prayerTransition) {
                    qiblaState = .found
                }
            } else if !isAligned && qiblaState == .found {
                withAnimation(AnimationConstants.prayerTransition) {
                    qiblaState = .searching
                }
            }
            wasAlignedWithQibla = isAligned

            if !isAligned {
                // Tick every 5 degrees of rotation
                let currentDegree = Int(offset) / 5
                if currentDegree != lastTickDegree {
                    lastTickDegree = currentDegree
                    Haptics.qiblaTick()
                }
            }
        }
        .onChange(of: viewModel.currentPrayer?.name) {
            Haptics.soft()
        }
    }

    @ViewBuilder
    private var qiblaView: some View {
        VStack(spacing: 0) {
            // Compass strip overlays above the button without shifting layout
            ZStack {
                if (qiblaState == .searching || qiblaState == .found), locationService.heading != nil {
                    QiblaStripCompass(
                        heading: smoothedHeading,
                        qiblaDirection: viewModel.qiblaDirection
                    )
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottom)))
                }
            }
            .frame(height: (qiblaState == .searching || qiblaState == .found) ? 44 : 0)
            .clipped()
            .padding(.bottom, (qiblaState == .searching || qiblaState == .found) ? 8 : 0)

            Button {
                switch qiblaState {
                case .idle:
                    Haptics.light()
                    lastTickDegree = -999
                    wasAlignedWithQibla = false
                    withAnimation(.easeInOut(duration: 0.35)) {
                        qiblaState = .searching
                    }
                    locationService.startHeadingUpdates()
                case .searching:
                    Haptics.light()
                    wasAlignedWithQibla = false
                    withAnimation(.easeInOut(duration: 0.35)) {
                        qiblaState = .idle
                    }
                    locationService.stopHeadingUpdates()
                case .found:
                    Haptics.light()
                    wasAlignedWithQibla = false
                    withAnimation(.easeInOut(duration: 0.35)) {
                        qiblaState = .idle
                    }
                    locationService.stopHeadingUpdates()
                }
            } label: {
                HStack {
                    Spacer()

                    switch qiblaState {
                    case .idle:
                        Text("QIBLA")
                            .font(.system(size: 13, weight: .medium))
                            .kerning(2.0)
                            .foregroundStyle(colorScheme == .dark ? AptaColors.secondary : AptaColors.tertiary)
                    case .searching:
                        if let offset = qiblaOffset {
                            Text(abs(offset) <= qiblaThreshold ? "FOUND" : "QIBLA")
                                .font(.system(size: 13, weight: .medium))
                                .kerning(2.0)
                                .foregroundStyle(abs(offset) <= qiblaThreshold ? AptaColors.primary : (colorScheme == .dark ? AptaColors.secondary : AptaColors.tertiary))
                        } else {
                            Text("SEARCHING")
                                .font(.system(size: 13, weight: .medium))
                                .kerning(2.0)
                                .foregroundStyle(AptaColors.tertiary)
                        }
                    case .found:
                        if let offset = qiblaOffset, abs(offset) <= qiblaThreshold {
                            Text("FOUND")
                                .font(.system(size: 13, weight: .medium))
                                .kerning(2.0)
                                .foregroundStyle(AptaColors.primary)
                        } else {
                            Text("QIBLA")
                                .font(.system(size: 13, weight: .medium))
                                .kerning(2.0)
                                .foregroundStyle(colorScheme == .dark ? AptaColors.secondary : AptaColors.tertiary)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: selectedDate)
    }

    private var hijriNavigationRow: some View {
        let hijriDate = viewModel.hijriDateString(for: selectedDate).uppercased()
        return HStack(spacing: 12) {
            Button {
                Haptics.light()
                shiftSelectedDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AptaColors.secondary)
            }
            .frame(width: 24, height: 24)

            Button {
                Haptics.light()
                showDatePicker = true
            } label: {
                Text(hijriDate.isEmpty ? "TODAY" : hijriDate)
                    .font(.system(size: 13, weight: .regular))
                    .kerning(1.5)
                    .foregroundStyle(AptaColors.tertiary)
            }
            .frame(height: 24)

            Button {
                Haptics.light()
                shiftSelectedDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AptaColors.secondary)
            }
            .frame(width: 24, height: 24)
        }
        .frame(height: 24)
        .onChange(of: selectedDate) {
            let normalized = Calendar.current.startOfDay(for: selectedDate)
            dateChangeDirection = normalized >= lastSelectedDate ? 1 : -1
            lastSelectedDate = normalized
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = normalized
            }
        }
    }

    private func shiftSelectedDate(by days: Int) {
        if let shifted = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            dateChangeDirection = days >= 0 ? 1 : -1
            lastSelectedDate = selectedDate
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = Calendar.current.startOfDay(for: shifted)
            }
        }
    }

    private var contentTransition: AnyTransition {
        let insertionEdge: Edge = dateChangeDirection >= 0 ? .trailing : .leading
        let removalEdge: Edge = dateChangeDirection >= 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    @ViewBuilder
    private func currentTimeDisplay(for date: Date) -> some View {
        if settings.timeFormat == .twelve {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(timeFormatter.string(from: date))
                    .font(Typography.currentTime)
                    .kerning(Typography.currentTimeKerning)
                    .foregroundStyle(AptaColors.primary)
                    .monospacedDigit()
                Text(amPmFormatter.string(from: date))
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(AptaColors.tertiary)
            }
        } else {
            Text(timeFormatter.string(from: date))
                .font(Typography.currentTime)
                .kerning(Typography.currentTimeKerning)
                .foregroundStyle(AptaColors.primary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func upcomingTimeDisplay(for date: Date) -> some View {
        if settings.timeFormat == .twelve {
            HStack(spacing: 3) {
                Text(timeFormatter.string(from: date))
                    .font(Typography.upcomingPrayerTime)
                    .foregroundStyle(AptaColors.secondary)
                Text(amPmFormatter.string(from: date))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AptaColors.tertiary)
            }
        } else {
            Text(timeFormatter.string(from: date))
                .font(Typography.upcomingPrayerTime)
                .foregroundStyle(AptaColors.secondary)
        }
    }
}
