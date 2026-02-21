
import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    
    static weak var sharedIfYouHaveOne: AppStore?


    @Published private(set) var medications: [Medication] = []
    @Published private(set) var doseEvents: [DoseEvent] = []


    private let storage: UserDefaultsStorage


    init(storage: UserDefaultsStorage = .shared) {
        self.storage = storage
        Self.sharedIfYouHaveOne = self
        loadFromDisk()
    }


    private func loadFromDisk() {
        do {
            let snapshot = try storage.load()
            self.medications = snapshot.medications
            self.doseEvents = snapshot.doseEvents
        } catch {
            self.medications = []
            self.doseEvents = []
        }
    }

    private func persist() {
        do {
            let snapshot = AppSnapshot(medications: medications, doseEvents: doseEvents)
            try storage.save(snapshot)
        } catch {
        }
    }

    func resetAll() {
        medications = []
        doseEvents = []
        storage.reset()
    }


    func addMedication(_ medication: Medication) {
        medications.append(medication)
        sortMedications()
        persist()

        if medication.notificationsEnabled {
            NotificationManager.shared.scheduleMedication(medication)
        } else {
            NotificationManager.shared.removePending(for: medication.id)
        }
    }

    func updateMedication(_ medication: Medication) {
        guard let idx = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[idx] = medication
        sortMedications()
        persist()

        if medication.notificationsEnabled {
            NotificationManager.shared.scheduleMedication(medication)
        } else {
            NotificationManager.shared.removePending(for: medication.id)
        }
    }

    func deleteMedication(id: UUID) {
        medications.removeAll { $0.id == id }
        doseEvents.removeAll { $0.medicationId == id }
        persist()

        NotificationManager.shared.removePending(for: id)
    }
    
    func rescheduleAllNotifications() {
        for med in medications {
            if med.notificationsEnabled {
                NotificationManager.shared.scheduleMedication(med)
            } else {
                NotificationManager.shared.removePending(for: med.id)
            }
        }
    }

    func setNotificationsEnabled(for medicationId: UUID, enabled: Bool) {
        guard let idx = medications.firstIndex(where: { $0.id == medicationId }) else { return }
        var updated = medications
        updated[idx].notificationsEnabled = enabled
        updated[idx].updatedAt = Date()
        medications = updated
        persist()

        if enabled {
            NotificationManager.shared.scheduleMedication(updated[idx])
        } else {
            NotificationManager.shared.removePending(for: medicationId)
        }
    }

    private func sortMedications() {
        medications.sort { a, b in
            if a.intakeTime.hour != b.intakeTime.hour { return a.intakeTime.hour < b.intakeTime.hour }
            if a.intakeTime.minute != b.intakeTime.minute { return a.intakeTime.minute < b.intakeTime.minute }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    func medication(by id: UUID) -> Medication? {
        medications.first(where: { $0.id == id })
    }


    func upsertDoseEvent(_ event: DoseEvent) {
        if let idx = doseEvents.firstIndex(where: { $0.id == event.id }) {
            doseEvents[idx] = event
        } else {
            doseEvents.append(event)
        }
        sortDoseEvents()
        persist()
    }

    func markDoseEvent(id: UUID, status: IntakeStatus) {
        guard let idx = doseEvents.firstIndex(where: { $0.id == id }) else { return }
        doseEvents[idx].status = status
        doseEvents[idx].decidedAt = Date()
        persist()
    }

    private func sortDoseEvents() {
        doseEvents.sort { $0.scheduledAt < $1.scheduledAt }
    }

    func doseEvents(for day: Date, calendar: Calendar = .current) -> [DoseEvent] {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return doseEvents
            .filter { $0.scheduledAt >= start && $0.scheduledAt < end }
            .sorted { $0.scheduledAt < $1.scheduledAt }
    }
    
    @MainActor
    func logDose(medicationId: UUID,
                 scheduledAt: Date,
                 status: IntakeStatus) {

        if let idx = doseEvents.firstIndex(where: {
            $0.medicationId == medicationId &&
            $0.scheduledAt == scheduledAt
        }) {
            doseEvents[idx].status = status
            doseEvents[idx].decidedAt = Date()
        } else {
            let event = DoseEvent(
                id: UUID(),
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                status: status,
                decidedAt: Date()
            )
            doseEvents.append(event)
            sortDoseEvents()
        }

        persist()
    }
    
    @MainActor
    func ensureTodayScheduleExists() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        for med in medications {
            guard med.frequency.shouldSchedule(on: today, calendar: cal) else { continue }

            var comps = cal.dateComponents([.year, .month, .day], from: today)
            comps.hour = med.intakeTime.hour
            comps.minute = med.intakeTime.minute

            guard let scheduledAt = cal.date(from: comps) else { continue }

            let exists = doseEvents.contains { $0.medicationId == med.id && $0.scheduledAt == scheduledAt }
            if exists { continue }

            let ev = DoseEvent(
                id: UUID(),
                medicationId: med.id,
                scheduledAt: scheduledAt,
                status: .planned,
                decidedAt: nil
            )
            doseEvents.append(ev)
        }

        sortDoseEvents()
        persist()
    }
}
