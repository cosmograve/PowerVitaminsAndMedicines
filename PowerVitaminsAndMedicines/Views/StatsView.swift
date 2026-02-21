import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var range: StatsRange = .week

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavBar(title: "Statistics", showsBack: false, onBackTap: nil)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        rangePicker

                        complianceRing
                            .frame(maxWidth: .infinity)

                        Text("Daily tracker")
                            .font(AppFont.poppins(size: 38 / 2, weight: .semibold))
                            .foregroundColor(.white)

                        HStack(spacing: 14) {
                            legendDot(color: AppColors.green, title: "Taken")
                            legendDot(color: Color(hex: "B70F0F"), title: "Missed")
                        }

                        dailyBars

                        Text("Top medications for compliance")
                            .font(AppFont.poppins(size: 38 / 2, weight: .semibold))
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(topMedications, id: \.name) { item in
                                Text(item.name)
                                    .font(AppFont.poppins(size: 17, weight: .medium))
                                    .foregroundColor(AppColors.yellow)
                            }
                        }
                    }
                    .padding(.horizontal, AppLayout.sidePadding)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            store.ensureTodayScheduleExists()
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var rangePicker: some View {
        GeometryReader { proxy in
            let inset: CGFloat = 4
            let segmentWidth = (proxy.size.width - inset * 2) / CGFloat(StatsRange.allCases.count)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.cardSwamp.opacity(0.95))

                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(AppColors.yellow)
                    .frame(width: segmentWidth, height: 36)
                    .offset(x: inset + segmentWidth * CGFloat(range.index))
                    .animation(.easeInOut(duration: 0.2), value: range)

                HStack(spacing: 0) {
                    ForEach(StatsRange.allCases, id: \.self) { item in
                        Button {
                            range = item
                        } label: {
                            Text(item.title)
                                .font(AppFont.poppins(size: 15, weight: .medium))
                                .foregroundColor(range == item ? .black : .white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, inset)
            }
        }
        .frame(height: 44)
    }

    private var complianceRing: some View {
        let pct = compliancePercent
        return ZStack {
            Circle()
                .stroke(AppColors.gray.opacity(0.7), lineWidth: 14)
            Circle()
                .trim(from: 0, to: CGFloat(pct) / 100)
                .stroke(AppColors.yellow, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("\(Int(round(pct)))%")
                    .font(AppFont.poppins(size: 64 / 2, weight: .semibold))
                    .foregroundColor(AppColors.yellow)
                Text("Overall compliance rate")
                    .font(AppFont.poppins(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .frame(width: 250, height: 250)
        .padding(.vertical, 6)
    }

    private var dailyBars: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(dailyTracker) { day in
                VStack(spacing: 8) {
                    dailyBar(for: day)

                    Text(day.title)
                        .font(AppFont.poppins(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var eventsInRange: [DoseEvent] {
        let now = Date()
        let calendar = Calendar.current
        let start: Date

        switch range {
        case .week:
            start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        case .month:
            start = calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now)) ?? now
        case .year:
            start = calendar.date(byAdding: .day, value: -364, to: calendar.startOfDay(for: now)) ?? now
        }

        return store.doseEvents.filter { $0.scheduledAt >= start && $0.scheduledAt <= now }
    }

    private var compliancePercent: Double {
        let decided = eventsInRange.filter { $0.status == .taken || $0.status == .missed }
        guard !decided.isEmpty else { return 0 }
        let taken = decided.filter { $0.status == .taken }.count
        return (Double(taken) / Double(decided.count)) * 100.0
    }

    private var topMedications: [(name: String, rate: Double)] {
        let decided = eventsInRange.filter { $0.status == .taken || $0.status == .missed }
        let grouped = Dictionary(grouping: decided, by: \.medicationId)
        let items: [(name: String, rate: Double)] = grouped.compactMap { medId, events in
            guard let med = store.medication(by: medId), !events.isEmpty else { return nil }
            let taken = events.filter { $0.status == .taken }.count
            let rate = Double(taken) / Double(events.count)
            return (med.name, rate)
        }
        return items.sorted { $0.rate > $1.rate }.prefix(3).map { $0 }
    }

    private var dailyTracker: [StatsDailyItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        switch range {
        case .week:
            let startOfWeek = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            ) ?? today
            let weekDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
            return weekDays.map { day in
                statsItem(for: day, title: weekdayShort(day))
            }

        case .month:
            let recentDays = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0 - 6, to: today) }
            return recentDays.map { day in
                statsItem(for: day, title: weekdayShort(day))
            }

        case .year:
            let startOfCurrentMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: today)
            ) ?? today
            let months = (0..<7).compactMap { calendar.date(byAdding: .month, value: $0 - 6, to: startOfCurrentMonth) }
            return months.map { monthStart in
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                let events = store.doseEvents.filter { $0.scheduledAt >= monthStart && $0.scheduledAt < monthEnd }
                let taken = events.filter { $0.status == .taken }.count
                let missed = events.filter { $0.status == .missed }.count
                let total = events.count
                return StatsDailyItem(
                    id: UUID(),
                    title: monthShort(monthStart),
                    taken: min(taken, 5),
                    missed: min(missed, 5),
                    total: min(total, 5)
                )
            }
        }
    }

    private func weekdayShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func legendDot(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(AppFont.poppins(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private func statsItem(for day: Date, title: String) -> StatsDailyItem {
        let events = store.doseEvents(for: day)
        let taken = events.filter { $0.status == .taken }.count
        let missed = events.filter { $0.status == .missed }.count
        let total = events.count
        return StatsDailyItem(
            id: UUID(),
            title: title,
            taken: min(taken, 5),
            missed: min(missed, 5),
            total: min(total, 5)
        )
    }

    private func monthShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    private func dailyBar(for day: StatsDailyItem) -> some View {
        let capTotal = max(1, day.total)
        let greenRatio = min(1, Double(day.taken) / Double(capTotal))
        let redRatio = min(1, Double(day.missed) / Double(capTotal))
        let greenHeight = CGFloat(greenRatio) * 104.0
        let redHeight = CGFloat(redRatio) * 104.0

        return ZStack {
            Capsule()
                .fill(AppColors.gray.opacity(0.75))
                .frame(width: 26, height: 104)

            if redHeight > 0 || greenHeight > 0 {
                VStack(spacing: 0) {
                    if redHeight > 0 {
                        Rectangle()
                            .fill(Color(hex: "B70F0F"))
                            .frame(width: 26, height: max(redHeight, 8))
                    }
                    if greenHeight > 0 {
                        Rectangle()
                            .fill(AppColors.green)
                            .frame(width: 26, height: max(greenHeight, 8))
                    }
                }
                .frame(width: 26, height: min(104, redHeight + greenHeight), alignment: .top)
                .frame(width: 26, height: 104, alignment: .bottom)
                .clipShape(Capsule())
            }
        }
        .background(
            Capsule()
                .fill(AppColors.cardSwamp.opacity(0.95))
                .frame(width: 26, height: 104)
        )
    }
}

#Preview {
    StatsView()
        .environmentObject(AppStore())
}

private enum StatsRange: CaseIterable {
    case week
    case month
    case year

    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    var index: Int {
        switch self {
        case .week: return 0
        case .month: return 1
        case .year: return 2
        }
    }
}

private struct StatsDailyItem: Identifiable {
    let id: UUID
    let title: String
    let taken: Int
    let missed: Int
    let total: Int
}
