import SwiftUI
import MapKit

struct LocationPickerView: View {
    @ObservedObject var locationService: LocationService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var query = ""
    @State private var results: [ManualPrayerLocation] = []
    @State private var isSearching = false
    @State private var message: String?
    @State private var activeSearch: MKLocalSearch?
    @State private var showPermissionAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        locationService.refreshAuthorizationState()
                        if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                            showPermissionAlert = true
                        } else {
                            locationService.useCurrentLocation()
                            dismiss()
                        }
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                    }
                    if let selected = locationService.manualLocation {
                        VStack(alignment: .leading, spacing: 4) {
                            Label(selected.city, systemImage: "mappin.and.ellipse")
                            Text(selected.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Choose a city to plan ahead. Prayer times, notifications, widgets, and Apple Watch will use that city's local time until you switch back to your current location.")
                }

                Section {
                    if isSearching {
                        HStack { ProgressView(); Text("Searching cities…").foregroundStyle(.secondary) }
                    }
                    ForEach(results, id: \.self) { result in
                        Button {
                            locationService.selectManualLocation(result)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.city).foregroundStyle(.primary)
                                Text(result.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let message {
                        Text(message).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search city or town")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task(id: query) { await search() }
            .onDisappear { activeSearch?.cancel() }
            .alert("Location Access Needed", isPresented: $showPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Allow location access in iOS Settings to use your current location. You can still choose a city manually.")
            }
        }
    }

    @MainActor
    private func search() async {
        activeSearch?.cancel()
        results = []
        message = nil
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else { isSearching = false; return }
        isSearching = true
        do {
            try await Task.sleep(for: .milliseconds(350))
            try Task.checkCancellation()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = text
            request.resultTypes = .address
            let search = MKLocalSearch(request: request)
            activeSearch = search
            let response = try await search.start()
            try Task.checkCancellation()
            var seen = Set<String>()
            results = response.mapItems.compactMap { item in
                let place = item.placemark
                guard let city = place.locality ?? place.subAdministrativeArea,
                      let timeZone = item.timeZone ?? place.timeZone else { return nil }
                let detail = [place.administrativeArea, place.country].compactMap { $0 }.joined(separator: ", ")
                guard seen.insert("\(city)|\(detail)").inserted else { return nil }
                return ManualPrayerLocation(city: city, detail: detail,
                                            latitude: place.coordinate.latitude,
                                            longitude: place.coordinate.longitude,
                                            timeZoneIdentifier: timeZone.identifier)
            }
            if results.isEmpty { message = "No cities found. Try adding a state or country to your search." }
            isSearching = false
        } catch {
            guard !Task.isCancelled else { return }
            message = "Couldn't search for cities. Check your connection and try again."
            isSearching = false
        }
    }
}
