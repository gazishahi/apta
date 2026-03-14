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
    @State private var headingHistory: [Double] = []
    @State private var headingUnstable: Bool = false
    @State private var cachedPrayers: [Date: [PrayerTimeEntry]] = [:]

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

    private func invalidateCache() {
        cachedPrayers.removeAll()
    }
    private let headingStabilityThreshold: Double = 30.0
    private let headingHistorySize: Int = 5

    private var qiblaOffset: Double? {
        guard let heading = locationService.heading else { return nil }
        var diff = viewModel.qiblaDirection - heading
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    var body: some View {
        ZStack {
            ThemeColors.backgroundColor(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                if settings.simpleMode {
                    simpleModeContent
                } else {
                    VStack(spacing: 0) {
                        dateNavigationSection
                        prayerContentSection
                    }
                }

                Spacer()

                qiblaView
                    .padding(.bottom, 24)
            }
        }
        .overlay {
            if showDatePicker {
                datePickerOverlay
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDatePicker)
        .animation(AnimationConstants.prayerTransition, value: viewModel.currentPrayer?.name)
        .onChange(of: locationService.heading) { _, _ in handleHeadingChange() }
        .onChange(of: viewModel.currentPrayer?.name) { _, _ in Haptics.soft() }
        .onChange(of: PrayerSettings.current) { _, _ in invalidateCache() }
        .onChange(of: selectedDate) { _, newDate in cachePrayers(for: newDate) }
        .onAppear { cachePrayers(for: selectedDate) }
    }

    private var topBar: some View {
        HStack {
            if !settings.simpleMode && !locationService.locationName.isEmpty {
                Text(locationService.locationName.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
            }
            Spacer()
            Button {
                Haptics.light()
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var dateNavigationSection: some View {
        VStack(spacing: 0) {
            hijriNavigationRow
                .padding(.bottom, 6)

            secondaryCalendarDate
                .padding(.bottom, 6)

            Button {
                Haptics.light()
                selectedDate = Calendar.current.startOfDay(for: Date())
            } label: {
                let calendar = Calendar.current
                let selectedStart = calendar.startOfDay(for: selectedDate)
                let todayStart = calendar.startOfDay(for: Date())
                let daysToToday = calendar.dateComponents([.day], from: selectedStart, to: todayStart).day ?? 0
                HStack(spacing: 4) {
                    if daysToToday < 0 {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                        Text("TODAY")
                            .font(.system(size: 11, weight: .medium))
                            .kerning(1.2)
                            .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                    } else if daysToToday > 0 {
                        Text("TODAY")
                            .font(.system(size: 11, weight: .medium))
                            .kerning(1.2)
                            .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                    } else {
                        Text("")
                            .font(.system(size: 11, weight: .medium))
                            .kerning(1.2)
                            .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                    }
                }
            }
            .frame(height: 24)
        }
    }

    private var dateRange: ClosedRange<Int> {
        -30...30
    }

    private var prayerContentSection: some View {
        TabView(selection: $selectedDate) {
            ForEach(generateDateRange(), id: \.self) { date in
                PrayerDayView(
                    date: date,
                    isToday: Calendar.current.isDateInToday(date),
                    viewModel: viewModel,
                    settings: settings,
                    cachedPrayers: cachedPrayers[date] ?? viewModel.prayers(for: date)
                )
                .tag(date)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.25), value: selectedDate)
    }

    private var simpleModeContent: some View {
        VStack(spacing: 0) {
            

            if let current = viewModel.currentPrayer {
                VStack(spacing: 8) {
                    Text(current.name.rawValue.uppercased())
                        .font(Typography.currentPrayerName)
                        .kerning(Typography.currentPrayerNameKerning)
                        .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))

                    currentTimeDisplay(for: current.time)

                    Text(viewModel.countdown)
                        .font(Typography.countdown)
                        .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                }
            }

            Spacer()
                .frame(height: 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var datePickerTint: Color {
        let theme = BackgroundTheme.current
        let effectiveScheme = theme.effectiveColorScheme(for: colorScheme)
        return effectiveScheme == .dark
            ? Color(red: 0.5, green: 0.65, blue: 1.0)
            : Color(uiColor: .systemBlue)
    }

    private var datePickerOverlay: some View {
        ZStack {
            let theme = BackgroundTheme.current
            let effectiveScheme = theme.effectiveColorScheme(for: colorScheme)
            Color.black.opacity(effectiveScheme == .dark ? 0.6 : 0.3)
                .ignoresSafeArea()
                .onTapGesture { showDatePicker = false }

            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .frame(width: 320)
                .id(selectedDate)
                .tint(datePickerTint)
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Button("Done") {
                    showDatePicker = false
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ThemeColors.textColor(for: colorScheme))
                .padding(.bottom, 16)
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.98).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var qiblaView: some View {
        VStack(spacing: 0) {
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
                toggleQiblaState()
            } label: {
                HStack {
                    Spacer()
                    qiblaButtonText
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDate)
    }

    @ViewBuilder
    private var qiblaButtonText: some View {
        switch qiblaState {
        case .idle:
            Text("QIBLA")
                .font(.system(size: 13, weight: .medium))
                .kerning(2.0)
                .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
        case .searching:
            if headingUnstable {
                Text("STABILIZE")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(2.0)
                    .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
            } else if let offset = qiblaOffset {
                Text(abs(offset) <= qiblaThreshold ? "FOUND" : "QIBLA")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(2.0)
                    .foregroundStyle(abs(offset) <= qiblaThreshold ? ThemeColors.textColor(for: colorScheme) : ThemeColors.tertiaryTextColor(for: colorScheme))
            } else {
                Text("SEARCHING")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(2.0)
                    .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
            }
        case .found:
            if let offset = qiblaOffset, abs(offset) <= qiblaThreshold {
                Text("FOUND")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(2.0)
                    .foregroundStyle(ThemeColors.textColor(for: colorScheme))
            } else {
                Text("QIBLA")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(2.0)
                    .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
            }
        }
    }

    private var hijriNavigationRow: some View {
        let hijriText = viewModel.hijriDateString(for: selectedDate).uppercased()
        _ = dateFormatter.string(from: selectedDate).uppercased()

        return HStack(spacing: 12) {
            Button {
                Haptics.light()
                shiftSelectedDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))
            }
            .frame(width: 24, height: 24)

            Button {
                Haptics.light()
                showDatePicker = true
            } label: {
                Text(hijriText.isEmpty ? "TODAY" : hijriText)
                    .font(.system(size: 13, weight: .regular))
                    .kerning(1.5)
                    .foregroundStyle(isToday ? ThemeColors.secondaryTextColor(for: colorScheme) : ThemeColors.tertiaryTextColor(for: colorScheme))
            }
            .frame(height: 24)

            Button {
                Haptics.light()
                shiftSelectedDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))
            }
            .frame(width: 24, height: 24)
        }
    }

    private var secondaryCalendarDate: some View {
        Text(dateFormatter.string(from: selectedDate).uppercased())
            .font(.system(size: 11, weight: .medium))
            .kerning(1.2)
            .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
    }

    private func toggleQiblaState() {
        switch qiblaState {
        case .idle:
            Haptics.light()
            lastTickDegree = -999
            wasAlignedWithQibla = false
            headingHistory = []
            headingUnstable = false
            withAnimation(.easeInOut(duration: 0.35)) {
                qiblaState = .searching
            }
            locationService.startHeadingUpdates()
        case .searching, .found:
            Haptics.light()
            wasAlignedWithQibla = false
            headingHistory = []
            headingUnstable = false
            withAnimation(.easeInOut(duration: 0.35)) {
                qiblaState = .idle
            }
            locationService.stopHeadingUpdates()
        }
    }

    private func handleHeadingChange() {
        guard let newHeading = locationService.heading else { return }

        var delta = newHeading - smoothedHeading
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        smoothedHeading += delta

        headingHistory.append(newHeading)
        if headingHistory.count > headingHistorySize {
            headingHistory.removeFirst()
        }

        if headingHistory.count >= 3 {
            let variance = calculateHeadingVariance()
            headingUnstable = variance > headingStabilityThreshold
        }

        guard (qiblaState == .searching || qiblaState == .found), let offset = qiblaOffset else { return }
        let isAligned = abs(offset) <= qiblaThreshold && !headingUnstable

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
            let currentDegree = Int(offset) / 5
            if currentDegree != lastTickDegree {
                lastTickDegree = currentDegree
                Haptics.qiblaTick()
            }
        }
    }

    private func calculateHeadingVariance() -> Double {
        guard headingHistory.count >= 2 else { return 0 }
        let diffs = zip(headingHistory, headingHistory.dropFirst()).map { abs($0 - $1) }
        let normalizedDiffs = diffs.map { diff in
            if diff > 180 { return 360 - diff }
            return diff
        }
        return normalizedDiffs.reduce(0, +) / Double(normalizedDiffs.count)
    }

    private func shiftSelectedDate(by days: Int) {
        if let shifted = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            dateChangeDirection = days >= 0 ? 1 : -1
            lastSelectedDate = selectedDate
            selectedDate = Calendar.current.startOfDay(for: shifted)
        }
    }

    private func generateDateRange() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-30...30).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    private func cachePrayers(for date: Date) {
        if cachedPrayers[date] == nil {
            cachedPrayers[date] = viewModel.prayers(for: date)
        }
    }

    @ViewBuilder
    private func currentTimeDisplay(for date: Date) -> some View {
        if settings.timeFormat == .twelve {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(timeFormatter.string(from: date))
                    .font(Typography.currentTime)
                    .kerning(Typography.currentTimeKerning)
                    .foregroundStyle(ThemeColors.textColor(for: colorScheme))
                    .monospacedDigit()
                Text(amPmFormatter.string(from: date))
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
            }
        } else {
            Text(timeFormatter.string(from: date))
                .font(Typography.currentTime)
                    .kerning(Typography.currentTimeKerning)
                    .foregroundStyle(ThemeColors.textColor(for: colorScheme))
                    .monospacedDigit()
        }
    }

    @ViewBuilder
    private func upcomingTimeDisplay(for date: Date) -> some View {
        if settings.timeFormat == .twelve {
            HStack(spacing: 3) {
                Text(timeFormatter.string(from: date))
                    .font(Typography.upcomingPrayerTime)
                    .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))
                Text(amPmFormatter.string(from: date))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
            }
        } else {
            Text(timeFormatter.string(from: date))
                .font(Typography.upcomingPrayerTime)
                .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))
        }
    }
}
