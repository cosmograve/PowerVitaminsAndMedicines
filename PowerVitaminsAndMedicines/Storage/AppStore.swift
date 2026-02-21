
import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    
    static weak var sharedIfYouHaveOne: AppStore?

    // MARK: - Published state

    @Published private(set) var medications: [Medication] = []
    @Published private(set) var doseEvents: [DoseEvent] = []

    // MARK: - Dependencies

    private let storage: UserDefaultsStorage

    // MARK: - Init

    init(storage: UserDefaultsStorage = .shared) {
        self.storage = storage
        Self.sharedIfYouHaveOne = self
        loadFromDisk()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        do {
            let snapshot = try storage.load()
            self.medications = snapshot.medications
            self.doseEvents = snapshot.doseEvents
        } catch {
            // If decoding fails, start fresh (MVP behavior).
            self.medications = []
            self.doseEvents = []
        }
    }

    private func persist() {
        do {
            let snapshot = AppSnapshot(medications: medications, doseEvents: doseEvents)
            try storage.save(snapshot)
        } catch {
            // MVP: ignore / log if needed.
        }
    }

    func resetAll() {
        medications = []
        doseEvents = []
        storage.reset()
    }

    // MARK: - Medication CRUD

    func addMedication(_ medication: Medication) {
        medications.append(medication)
        sortMedications()
        persist()

        // Schedule notifications for this medication
        NotificationManager.shared.scheduleMedication(medication)
    }

    func updateMedication(_ medication: Medication) {
        guard let idx = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[idx] = medication
        sortMedications()
        persist()

        // Re-schedule notifications for updated rules/time
        NotificationManager.shared.scheduleMedication(medication)
    }

    func deleteMedication(id: UUID) {
        medications.removeAll { $0.id == id }
        doseEvents.removeAll { $0.medicationId == id }
        persist()

        // Remove pending notifications
        NotificationManager.shared.removePending(for: id)
    }
    
    func rescheduleAllNotifications() {
        for med in medications {
            NotificationManager.shared.scheduleMedication(med)
        }
    }

    private func sortMedications() {
        // Sort by intake time, then by name.
        medications.sort { a, b in
            if a.intakeTime.hour != b.intakeTime.hour { return a.intakeTime.hour < b.intakeTime.hour }
            if a.intakeTime.minute != b.intakeTime.minute { return a.intakeTime.minute < b.intakeTime.minute }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    func medication(by id: UUID) -> Medication? {
        medications.first(where: { $0.id == id })
    }

    // MARK: - Dose Events

    /// Upsert an event (useful when generating today's schedule).
    func upsertDoseEvent(_ event: DoseEvent) {
        if let idx = doseEvents.firstIndex(where: { $0.id == event.id }) {
            doseEvents[idx] = event
        } else {
            doseEvents.append(event)
        }
        sortDoseEvents()
        persist()
    }

    /// Mark an event as taken/missed.
    func markDoseEvent(id: UUID, status: IntakeStatus) {
        guard let idx = doseEvents.firstIndex(where: { $0.id == id }) else { return }
        doseEvents[idx].status = status
        doseEvents[idx].decidedAt = Date()
        persist()
    }

    private func sortDoseEvents() {
        doseEvents.sort { $0.scheduledAt < $1.scheduledAt }
    }

    /// Events for a specific day (calendar/notifications screen).
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

            // scheduledAt today + med.intakeTime
            var comps = cal.dateComponents([.year, .month, .day], from: today)
            comps.hour = med.intakeTime.hour
            comps.minute = med.intakeTime.minute

            guard let scheduledAt = cal.date(from: comps) else { continue }

            // If event already exists (taken/missed/pending) -> skip
            let exists = doseEvents.contains { $0.medicationId == med.id && $0.scheduledAt == scheduledAt }
            if exists { continue }

            // Create "planned" event with status .planned (or .pending)
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
