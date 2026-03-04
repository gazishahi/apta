import SwiftUI
import WidgetKit

struct SettingsView: View {
    @State private var settings = PrayerSettings.current
    var onSettingsChanged: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Theme", selection: $settings.theme) {
                        ForEach(PrayerSettings.AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                } header: {
                    sectionHeader("APPEARANCE")
                }

                Section {
                    Picker("Time Format", selection: $settings.timeFormat) {
                        ForEach(PrayerSettings.TimeFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    sectionHeader("TIME FORMAT")
                }

                Section {
                    Picker("Method", selection: $settings.calculationMethod) {
                        ForEach(AppCalculationMethod.allCases.filter { $0 != .other }) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                } header: {
                    sectionHeader("CALCULATION METHOD")
                }

                Section {
                    Picker("Asr Method", selection: $settings.asrMethod) {
                        ForEach(PrayerSettings.AsrMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    sectionHeader("ASR CALCULATION")
                }

                Section {
                    Picker("Rule", selection: $settings.highLatitudeRule) {
                        ForEach(PrayerSettings.AppHighLatitudeRule.allCases) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    sectionHeader("HIGH LATITUDE")
                }

                Section {
                    Stepper("Adjustment: \(settings.hijriAdjustment > 0 ? "+" : "")\(settings.hijriAdjustment) day\(abs(settings.hijriAdjustment) == 1 ? "" : "s")", value: $settings.hijriAdjustment, in: -2...2)
                } header: {
                    sectionHeader("HIJRI DATE")
                } footer: {
                    Text("Adjust the Hijri date if it differs from your local moonsighting.")
                }

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
                        .pickerStyle(.inline)

                        Toggle("Fajr", isOn: $settings.fajrNotification)
                        Toggle("Dhuhr", isOn: $settings.dhuhrNotification)
                        Toggle("Asr", isOn: $settings.asrNotification)
                        Toggle("Maghrib", isOn: $settings.maghribNotification)
                        Toggle("Isha", isOn: $settings.ishaNotification)

                        Toggle("Ramadan Alerts", isOn: $settings.ramadanNotificationsEnabled)
                    }
                } header: {
                    sectionHeader("NOTIFICATIONS")
                }

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
            .onChange(of: settings.calculationMethod) { save() }
            .onChange(of: settings.asrMethod) { save() }
            .onChange(of: settings.highLatitudeRule) { save() }
            .onChange(of: settings.theme) { save() }
            .onChange(of: settings.timeFormat) { save() }
            .onChange(of: settings.hijriAdjustment) { save() }
            .onChange(of: settings.notificationStyle) { save() }
            .onChange(of: settings.ramadanNotificationsEnabled) { save() }
            .onChange(of: settings.fajrNotification) { save() }
            .onChange(of: settings.dhuhrNotification) { save() }
            .onChange(of: settings.asrNotification) { save() }
            .onChange(of: settings.maghribNotification) { save() }
            .onChange(of: settings.ishaNotification) { save() }
        }
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
