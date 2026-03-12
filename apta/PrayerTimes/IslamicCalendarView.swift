import SwiftUI

struct IslamicCalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date
    let hijriAdjustment: Int

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        calendarView.calendar = islamicCalendar
        calendarView.locale = Locale(identifier: "en")
        calendarView.fontDesign = .default
        calendarView.delegate = context.coordinator
        calendarView.availableDateRange = DateInterval(start: .distantPast, end: .distantFuture)

        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = dateSelection

        context.coordinator.calendarView = calendarView
        return calendarView
    }

    func updateUIView(_ calendarView: UICalendarView, context: Context) {
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)

        let adjustedSelectedDate = Calendar.current.date(byAdding: .day, value: hijriAdjustment, to: selectedDate) ?? selectedDate
        let components = islamicCalendar.dateComponents([.year, .month, .day], from: adjustedSelectedDate)

        if let selection = calendarView.selectionBehavior as? UICalendarSelectionSingleDate {
            if selection.selectedDate != components {
                selection.setSelected(components, animated: true)
            }
        }

        let adjustedToday = Calendar.current.date(byAdding: .day, value: hijriAdjustment, to: Date()) ?? Date()
        let todayComponents = islamicCalendar.dateComponents([.year, .month, .day], from: adjustedToday)

        var componentsToReload = [todayComponents, components]
        if let lastComponents = context.coordinator.lastSelectedComponents {
            componentsToReload.append(lastComponents)
        }

        calendarView.reloadDecorations(forDateComponents: componentsToReload, animated: false)
        context.coordinator.lastSelectedComponents = components
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        var parent: IslamicCalendarView
        weak var calendarView: UICalendarView?
        var lastSelectedComponents: DateComponents?

        init(_ parent: IslamicCalendarView) {
            self.parent = parent
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let components = dateComponents,
                  let islamicCalendar = calendarView?.calendar,
                  let gregorianDate = convertIslamicToGregorian(components, islamicCalendar: islamicCalendar) else {
                return
            }

            let adjustedDate = Calendar.current.date(byAdding: .day, value: -parent.hijriAdjustment, to: gregorianDate) ?? gregorianDate
            parent.selectedDate = Calendar.current.startOfDay(for: adjustedDate)
        }

        private func convertIslamicToGregorian(_ components: DateComponents, islamicCalendar: Calendar) -> Date? {
            guard let year = components.year,
                  let month = components.month,
                  let day = components.day else { return nil }

            var islamicComps = DateComponents()
            islamicComps.year = year
            islamicComps.month = month
            islamicComps.day = day

            guard let islamicDate = islamicCalendar.date(from: islamicComps) else { return nil }

            let gregorianCalendar = Calendar(identifier: .gregorian)
            return gregorianCalendar.date(bySettingHour: 12, minute: 0, second: 0, of: islamicDate)
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            let calendar = calendarView.calendar
            guard let date = calendar.date(from: dateComponents) else { return nil }

            let gregorian = Calendar(identifier: .gregorian)
            let todayInGregorian = gregorian.startOfDay(for: Date())
            let adjustedToday = gregorian.date(byAdding: .day, value: parent.hijriAdjustment, to: todayInGregorian) ?? todayInGregorian
            let todayInIslamic = calendar.startOfDay(for: adjustedToday)
            let isToday = calendar.isDate(date, inSameDayAs: todayInIslamic)

            let adjustedSelected = gregorian.date(byAdding: .day, value: parent.hijriAdjustment, to: parent.selectedDate) ?? parent.selectedDate
            let selectedInIslamic = calendar.startOfDay(for: adjustedSelected)
            let isSelected = calendar.isDate(date, inSameDayAs: selectedInIslamic)

            let isDarkMode = calendarView.traitCollection.userInterfaceStyle == .dark

            if isSelected && !isToday {
                return .customView {
                    let view = UIView()
                    view.backgroundColor = isDarkMode ? UIColor.white : UIColor.systemBlue
                    view.layer.cornerRadius = 16
                    let label = UILabel()
                    label.text = "\(dateComponents.day ?? 1)"
                    label.textColor = isDarkMode ? UIColor.black : UIColor.white
                    label.font = .systemFont(ofSize: 16, weight: .semibold)
                    label.textAlignment = .center
                    label.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(label)
                    NSLayoutConstraint.activate([
                        view.widthAnchor.constraint(equalToConstant: 32),
                        view.heightAnchor.constraint(equalToConstant: 32),
                        label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                    ])
                    return view
                }
            } else if isToday && !isSelected {
                return .customView {
                    let view = UIView()
                    view.backgroundColor = isDarkMode ? UIColor.white.withAlphaComponent(0.15) : UIColor.black.withAlphaComponent(0.08)
                    view.layer.cornerRadius = 16
                    view.layer.borderWidth = 2
                    view.layer.borderColor = isDarkMode ? UIColor.white.withAlphaComponent(0.5).cgColor : UIColor.secondaryLabel.cgColor
                    let label = UILabel()
                    label.text = "\(dateComponents.day ?? 1)"
                    label.textColor = isDarkMode ? UIColor.white : UIColor.label
                    label.font = .systemFont(ofSize: 16, weight: .medium)
                    label.textAlignment = .center
                    label.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(label)
                    NSLayoutConstraint.activate([
                        view.widthAnchor.constraint(equalToConstant: 32),
                        view.heightAnchor.constraint(equalToConstant: 32),
                        label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                    ])
                    return view
                }
            } else if isSelected && isToday {
                return .customView {
                    let view = UIView()
                    view.backgroundColor = isDarkMode ? UIColor.white : UIColor.systemBlue
                    view.layer.cornerRadius = 16
                    let label = UILabel()
                    label.text = "\(dateComponents.day ?? 1)"
                    label.textColor = UIColor.white
                    label.font = .systemFont(ofSize: 16, weight: .semibold)
                    label.textAlignment = .center
                    label.translatesAutoresizingMaskIntoConstraints = false
                    view.addSubview(label)
                    NSLayoutConstraint.activate([
                        view.widthAnchor.constraint(equalToConstant: 32),
                        view.heightAnchor.constraint(equalToConstant: 32),
                        label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                        label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
                    ])
                    return view
                }
            }

            return nil
        }
    }
}
