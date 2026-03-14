import SwiftUI
import WidgetKit
import StoreKit

struct BackgroundSettingsView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var theme = BackgroundTheme.current
    @State private var showPaywall = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            if UserDefaults(suiteName: "group.Gazi.apta")?.bool(forKey: "isProUser") ?? false {
                HStack {
                    Spacer()
                    Text("apta pro")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .padding(.vertical, 8)
            }
            
            Section {
                previewCard
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowBackground(Color.clear)
            }



            Section {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    defaultButton
                    ForEach(BackgroundPreset.allCases) { preset in
                        colorButton(for: preset)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("BACKGROUND COLOR")
                    .font(Typography.settingsHeader)
                    .kerning(Typography.settingsHeaderKerning)
            }

            Section {
                Toggle("Adaptive", isOn: adaptiveBinding)
                    .disabled(!purchaseManager.isProUser || theme.preset == nil)
            } footer: {
                if theme.preset == nil || theme.isAdaptive {
                    Text("When enabled, the background automatically switches between light and dark variants based on your system theme. When disabled, you can choose a specific variant.")
                }
            }

            if theme.preset != nil && !theme.isAdaptive {
                Section {
                    Picker("Variant", selection: variantBinding) {
                        ForEach(BackgroundVariant.allCases) { variant in
                            Text(variant.displayName).tag(variant)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("VARIANT")
                        .font(Typography.settingsHeader)
                        .kerning(Typography.settingsHeaderKerning)
                } footer: {
                    Text("Choose which variant to use when adaptive mode is disabled.")
                }
            }
        }
        .navigationTitle("Background")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var previewCard: some View {
        let effectiveScheme = theme.effectiveColorScheme(for: colorScheme)
        let bgColor = theme.backgroundColor(for: effectiveScheme) ?? AptaColors.background
        let textColor = theme.textColor(for: effectiveScheme) ?? AptaColors.primary

        return VStack(spacing: 12) {
            Text("FAJR")
                .font(.system(size: 14, weight: .medium))
                .kerning(2)
                .foregroundStyle(textColor)

            Text("5:30 AM")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(textColor)

            Text("in 2h 15m")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var defaultButton: some View {
        let isSelected = theme.preset == nil

        return Button {
            Haptics.light()
            theme.preset = nil
            save()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.black : Color.white)
                        .frame(height: 44)
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AptaColors.separator, lineWidth: 1)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )

                Text("Default")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AptaColors.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func colorButton(for preset: BackgroundPreset) -> some View {
        let isSelected = theme.preset == preset
        let previewColor = colorScheme == .dark ? preset.darkColor : preset.lightColor

        return Button {
            Haptics.light()
            if purchaseManager.isProUser {
                theme.preset = preset
                save()
            } else {
                showPaywall = true
            }
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(previewColor)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .overlay {
                        if !purchaseManager.isProUser {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                Text(preset.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AptaColors.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var adaptiveBinding: Binding<Bool> {
        Binding(
            get: { theme.isAdaptive },
            set: { newValue in
                theme.isAdaptive = newValue
                save()
            }
        )
    }

    private var variantBinding: Binding<BackgroundVariant> {
        Binding(
            get: { theme.preferredVariant },
            set: { newValue in
                theme.preferredVariant = newValue
                save()
            }
        )
    }

    private func save() {
        BackgroundTheme.current = theme
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct PaywallView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 8) {
                    Text("Unlock Backgrounds")
                        .font(.system(size: 24, weight: .semibold))

                    Text("Personalize apta with custom background colors for the app and widgets.")
                        .font(.system(size: 15))
                        .foregroundStyle(AptaColors.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 12) {
                    if let product = purchaseManager.product {
                        Button {
                            Task {
                                if await purchaseManager.purchase() {
                                    dismiss()
                                }
                            }
                        } label: {
                            if purchaseManager.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Buy for \(product.displayPrice)")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    } else if purchaseManager.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        if let error = purchaseManager.errorMessage {
                            VStack(spacing: 8) {
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            await purchaseManager.restorePurchases()
                            if purchaseManager.isProUser {
                                dismiss()
                            }
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(AptaColors.secondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await purchaseManager.loadProduct()
        }
    }
}
