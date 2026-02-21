import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedMedicationForActions: Medication? = nil

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavBar(title: "Reminders", showsBack: false, onBackTap: nil)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if activeReminders.isEmpty {
                            VStack(spacing: 18) {
                                Image(systemName: "nosign")
                                    .font(.system(size: 88, weight: .regular))
                                    .foregroundColor(.white.opacity(0.95))

                                Text("You don't have any\nReminders.")
                                    .font(AppFont.poppins(size: 38 / 2, weight: .regular))
                                    .foregroundColor(.white.opacity(0.95))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 140)
                        } else {
                            Text("Active reminders for today:")
                                .font(AppFont.poppins(size: 40 / 2, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.bottom, 2)

                            ForEach(activeReminders) { reminder in
                                Button {
                                    selectedMedicationForActions = reminder.medication
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(timeString(reminder.time))
                                            .font(AppFont.poppins(size: 14, weight: .semibold))
                                            .foregroundColor(AppColors.yellow)

                                        Text(reminder.medication.name)
                                            .font(AppFont.poppins(size: 36 / 2, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .frame(height: 84)
                                    .background(AppColors.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                }
                                .buttonStyle(.plain)
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
        .confirmationDialog(
            "Reminder options",
            isPresented: Binding(
                get: { selectedMedicationForActions != nil },
                set: { if !$0 { selectedMedicationForActions = nil } }
            ),
            titleVisibility: .visible,
            presenting: selectedMedicationForActions
        ) { med in
            if med.notificationsEnabled {
                Button("Disable reminders", role: .destructive) {
                    store.setNotificationsEnabled(for: med.id, enabled: false)
                }
            } else {
                Button("Enable reminders") {
                    store.setNotificationsEnabled(for: med.id, enabled: true)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var activeReminders: [ReminderItem] {
        let today = Calendar.current.startOfDay(for: Date())
        return store.medications
            .filter { $0.notificationsEnabled && $0.frequency.shouldSchedule(on: today) }
            .map { med in
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: today)
                comps.hour = med.intakeTime.hour
                comps.minute = med.intakeTime.minute
                let time = Calendar.current.date(from: comps) ?? today
                return ReminderItem(id: med.id, medication: med, time: time)
            }
            .sorted { $0.time < $1.time }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NotificationsView()
        .environmentObject(AppStore())
}

private struct ReminderItem: Identifiable {
    let id: UUID
    let medication: Medication
    let time: Date
}
