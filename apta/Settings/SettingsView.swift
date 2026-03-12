import SwiftUI
import WidgetKit

struct SettingsView: View {
    @State private var settings = PrayerSettings.current
    @State private var advancedExpanded = false
    @State private var prayersExpanded = false
    var onSettingsChanged: () -> Void

    var body: some View {
        List {
            // SECTION 1: APPEARANCE
            Section {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(PrayerSettings.AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.menu)

                Picker("Text Size", selection: $settings.prayerFontSize) {
                    ForEach(PrayerSettings.PrayerFontSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.menu)

                Picker("Time Format", selection: $settings.timeFormat) {
                    ForEach(PrayerSettings.TimeFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Simple Mode", isOn: $settings.simpleMode)
                Toggle("Show Ishraq", isOn: $settings.showIshraq)
            } header: {
                sectionHeader("APPEARANCE")
            }

            // SECTION 2: PRAYER CALCULATION
            Section {
                Picker("Method", selection: $settings.calculationMethod) {
                    ForEach(AppCalculationMethod.allCases.filter { $0 != .other }) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.menu)

                Picker("Asr Method", selection: $settings.asrMethod) {
                    ForEach(PrayerSettings.AsrMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.menu)

                DisclosureGroup("Advanced", isExpanded: $advancedExpanded) {
                    Picker("High Latitude Rule", selection: $settings.highLatitudeRule) {
                        ForEach(PrayerSettings.AppHighLatitudeRule.allCases) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Custom Fajr Angle", isOn: fajrAngleBinding)
                    if settings.customFajrAngle != nil {
                        Stepper("Fajr: \(String(format: "%.1f", settings.customFajrAngle ?? 15.0))°", value: fajrAngleValue, in: 5.0...25.0, step: 0.5)
                    }

                    Toggle("Custom Isha Angle", isOn: ishaAngleBinding)
                    if settings.customIshaAngle != nil {
                        Stepper("Isha: \(String(format: "%.1f", settings.customIshaAngle ?? 15.0))°", value: ishaAngleValue, in: 5.0...25.0, step: 0.5)
                    }
                }
            } header: {
                sectionHeader("PRAYER CALCULATION")
            }

            // SECTION 3: HIJRI DATE
            Section {
                Picker("Calendar Type", selection: $settings.calendarType) {
                    ForEach(PrayerSettings.CalendarType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)

                Stepper("Adjustment: \(settings.hijriAdjustment > 0 ? "+" : "")\(settings.hijriAdjustment) day\(abs(settings.hijriAdjustment) == 1 ? "" : "s")", value: $settings.hijriAdjustment, in: -2...2)
            } header: {
                sectionHeader("HIJRI DATE")
            } footer: {
                Text("Adjust the Hijri date if it differs from your local moonsighting.")
            }

            // SECTION 4: NOTIFICATIONS
            Section {
                Toggle("Prayer Notifications", isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) {
                        if settings.notificationsEnabled {
                            Task {
                                let granted = await NotificationScheduler.requestPermission()
                                if !granted {
                                    settings.notificationsEnabled = false
                                }
                                save()
                            }
                        } else {
                            NotificationScheduler.cancelAll()
                            save()
                        }
                    }

                if settings.notificationsEnabled {
                    Picker("Style", selection: $settings.notificationStyle) {
                        ForEach(PrayerSettings.NotificationStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)

                    DisclosureGroup("Prayer Alerts", isExpanded: $prayersExpanded) {
                        Toggle("Fajr", isOn: $settings.fajrNotification)
                        Toggle("Dhuhr", isOn: $settings.dhuhrNotification)
                        Toggle("Asr", isOn: $settings.asrNotification)
                        Toggle("Maghrib", isOn: $settings.maghribNotification)
                        Toggle("Isha", isOn: $settings.ishaNotification)
                        if settings.showIshraq {
                            Toggle("Ishraq", isOn: $settings.ishraqNotification)
                        }
                    }

                    Toggle("Ramadan Alerts", isOn: $settings.ramadanNotificationsEnabled)
                }
            } header: {
                sectionHeader("NOTIFICATIONS")
            }

            // VERSION FOOTER
            Section {
                HStack {
                    Spacer()
                    Text("apta v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings) { _ in save() }
    }

    private var fajrAngleBinding: Binding<Bool> {
        Binding(
            get: { settings.customFajrAngle != nil },
            set: { enabled in
                settings.customFajrAngle = enabled ? 15.0 : nil
                save()
            }
        )
    }

    private var ishaAngleBinding: Binding<Bool> {
        Binding(
            get: { settings.customIshaAngle != nil },
            set: { enabled in
                settings.customIshaAngle = enabled ? 15.0 : nil
                save()
            }
        )
    }

    private var fajrAngleValue: Binding<Double> {
        Binding(
            get: { settings.customFajrAngle ?? 15.0 },
            set: { settings.customFajrAngle = $0; save() }
        )
    }

    private var ishaAngleValue: Binding<Double> {
        Binding(
            get: { settings.customIshaAngle ?? 15.0 },
            set: { settings.customIshaAngle = $0; save() }
        )
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Typography.settingsHeader)
            .kerning(Typography.settingsHeaderKerning)
    }

    private func save() {
        PrayerSettings.current = settings
        onSettingsChanged()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
