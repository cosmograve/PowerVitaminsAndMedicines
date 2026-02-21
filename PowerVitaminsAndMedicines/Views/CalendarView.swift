import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: AppStore

    @State private var selectedDate: Date = Date()
    @State private var displayedMonth: Date = Date()
    @State private var selectedEvent: DoseEvent? = nil

    private let calendar = Calendar.current
    private let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavBar(title: "Calendar", showsBack: false, onBackTap: nil)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        calendarCard

                        Text("Daily intake:")
                            .font(AppFont.poppins(size: 36 / 2, weight: .semibold))
                            .foregroundColor(AppColors.yellow)

                        if selectedDayItems.isEmpty {
                            Text("No intakes for selected date.")
                                .font(AppFont.poppins(size: 16, weight: .regular))
                                .foregroundColor(AppColors.gray)
                        } else {
                            ForEach(selectedDayItems) { item in
                                Button {
                                    selectedEvent = item.event
                                } label: {
                                    Text(item.medication.name)
                                        .font(AppFont.poppins(size: 36 / 2, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .frame(height: 64)
                                        .background(AppColors.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, AppLayout.sidePadding)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                }
            }
        }
        .fullScreenCover(item: $selectedEvent) { event in
            CalendarDetailSheet(event: event)
                .environmentObject(store)
        }
        .onAppear {
            store.ensureTodayScheduleExists()
            displayedMonth = calendar.startOfMonth(for: selectedDate)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var selectedDayItems: [CalendarMedicationItem] {
        store.doseEvents(for: selectedDate)
            .compactMap { event in
                guard let med = store.medication(by: event.medicationId) else { return nil }
                return CalendarMedicationItem(event: event, medication: med)
            }
            .sorted { $0.event.scheduledAt < $1.event.scheduledAt }
    }

    private var calendarCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(monthTitle(displayedMonth))
                    .font(AppFont.poppins(size: 30 / 2, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button { displayedMonth = calendar.month(byAdding: -1, to: displayedMonth) } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)

                Button { displayedMonth = calendar.month(byAdding: 1, to: displayedMonth) } label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }

            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(AppFont.poppins(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(monthGridDays(), id: \.self) { day in
                    let isCurrentMonth = calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
                    let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                    let hasEvent = !store.doseEvents(for: day).isEmpty

                    Button {
                        selectedDate = day
                    } label: {
                        ZStack {
                            Rectangle()
                                .fill(isSelected ? AppColors.yellow.opacity(0.18) : .clear)

                            Text("\(calendar.component(.day, from: day))")
                                .font(AppFont.poppins(size: 14, weight: .regular))
                                .foregroundColor(dayColor(isCurrentMonth: isCurrentMonth, hasEvent: hasEvent))
                        }
                        .frame(height: 42)
                        .overlay(
                            Rectangle().stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.cardSwamp.opacity(0.95))
        )
    }

    private func monthGridDays() -> [Date] {
        let monthStart = calendar.startOfMonth(for: displayedMonth)
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<2
        let numberOfDays = range.count
        let firstWeekday = calendar.mondayBasedWeekday(for: monthStart)
        let leadingDays = firstWeekday - 1

        var days: [Date] = []
        if let start = calendar.date(byAdding: .day, value: -leadingDays, to: monthStart) {
            for offset in 0..<42 {
                if let day = calendar.date(byAdding: .day, value: offset, to: start) {
                    days.append(day)
                }
            }
        }
        if days.isEmpty {
            return (0..<numberOfDays).compactMap { calendar.date(byAdding: .day, value: $0, to: monthStart) }
        }
        return days
    }

    private func dayColor(isCurrentMonth: Bool, hasEvent: Bool) -> Color {
        if !isCurrentMonth { return .white.opacity(0.35) }
        if hasEvent { return AppColors.yellow }
        return .white.opacity(0.85)
    }

    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppStore())
}

private struct CalendarDetailSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let event: DoseEvent

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 18) {
                AppNavBar(title: "Calendar Detail", showsBack: true, onBackTap: { dismiss() })

                if let med = store.medication(by: event.medicationId) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(med.name)
                            .font(AppFont.poppins(size: 44 / 2, weight: .semibold))
                            .foregroundColor(.white)
                        Text(med.subtitle)
                            .font(AppFont.poppins(size: 34 / 2, weight: .regular))
                            .foregroundColor(AppColors.yellow)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppLayout.sidePadding)

                    detailRow(title: "TimePicker", value: timeString(event.scheduledAt))
                    detailRow(title: "Frequency", value: med.frequency.title)
                }

                Spacer()
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.poppins(size: 16, weight: .semibold))
                .foregroundColor(AppColors.yellow)
            Text(value)
                .font(AppFont.poppins(size: 36 / 2, weight: .regular))
                .foregroundColor(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.cardSwamp.opacity(0.95))
        )
        .padding(.horizontal, AppLayout.sidePadding)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct CalendarMedicationItem: Identifiable {
    var id: UUID { event.id }
    let event: DoseEvent
    let medication: Medication
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }

    func month(byAdding value: Int, to date: Date) -> Date {
        self.date(byAdding: .month, value: value, to: date) ?? date
    }

    func mondayBasedWeekday(for date: Date) -> Int {
        let weekday = component(.weekday, from: date)
        return ((weekday + 5) % 7) + 1
    }
}
