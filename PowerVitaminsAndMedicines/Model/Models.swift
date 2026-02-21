import Foundation

// MARK: - Medication Category

/// Medication category (for icons/filters/stats).
enum MedicationCategory: String, Codable, CaseIterable, Identifiable {
    case vitamins
    case medicines
    case supplements

    var id: String { rawValue }

    /// Display title for UI.
    var title: String {
        switch self {
        case .vitamins: return "Vitamins"
        case .medicines: return "Medicines"
        case .supplements: return "Supplements"
        }
    }

    /// Emoji icon (as in the spec).
    var icon: String {
        switch self {
        case .vitamins: return "💊"
        case .medicines: return "💊"
        case .supplements: return "💊"
        }
    }
}

// MARK: - Frequency

/// Intake frequency.
/// MVP: daily / every other day / weekdays / custom weekdays.
enum MedicationFrequency: Codable, Equatable, Hashable {
    case daily
    case everyOtherDay(anchor: Date) // anchor date for "every other day"
    case weekdays
    case customWeekdays(Set<Weekday>)

    enum CodingKeys: String, CodingKey {
        case kind
        case anchor
        case weekdays
    }

    enum Kind: String, Codable {
        case daily
        case everyOtherDay
        case weekdays
        case customWeekdays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .daily:
            self = .daily
        case .everyOtherDay:
            let anchor = try container.decode(Date.self, forKey: .anchor)
            self = .everyOtherDay(anchor: anchor)
        case .weekdays:
            self = .weekdays
        case .customWeekdays:
            let days = try container.decode(Set<Weekday>.self, forKey: .weekdays)
            self = .customWeekdays(days)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .daily:
            try container.encode(Kind.daily, forKey: .kind)

        case .everyOtherDay(let anchor):
            try container.encode(Kind.everyOtherDay, forKey: .kind)
            try container.encode(anchor, forKey: .anchor)

        case .weekdays:
            try container.encode(Kind.weekdays, forKey: .kind)

        case .customWeekdays(let days):
            try container.encode(Kind.customWeekdays, forKey: .kind)
            try container.encode(days, forKey: .weekdays)
        }
    }

    /// Display title for UI.
    var title: String {
        switch self {
        case .daily: return "Daily"
        case .everyOtherDay: return "Every other day"
        case .weekdays: return "Weekdays"
        case .customWeekdays: return "Custom"
        }
    }
}


extension MedicationFrequency {

    func shouldSchedule(on day: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .daily:
            return true

        case .weekdays:
            let w = calendar.component(.weekday, from: day) // 1=Sun ... 7=Sat
            return w >= 2 && w <= 6

        case .everyOtherDay(let anchor):
            // Anchor-based alternation (0,2,4... days diff)
            let d1 = calendar.startOfDay(for: anchor)
            let d2 = calendar.startOfDay(for: day)
            let diff = calendar.dateComponents([.day], from: d1, to: d2).day ?? 0
            return diff % 2 == 0

        case .customWeekdays(let set):
            let w = Weekday.from(date: day, calendar: calendar)
            return set.contains(w)
        }
    }
}

// MARK: - Weekday

/// ISO weekday: Monday=1 ... Sunday=7.
enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7

    var id: Int { rawValue }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var shortTitle: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}


extension Weekday {
    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        let w = calendar.component(.weekday, from: date)
        switch w {
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }
}

// MARK: - Time Of Day

/// A time-of-day without a date.
/// Stores hour/minute - enough for scheduling notifications and generating events.
struct TimeOfDay: Codable, Hashable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }

    /// Create from Date (e.g. from DatePicker).
    init(date: Date, calendar: Calendar = .current) {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: comps.hour ?? 0, minute: comps.minute ?? 0)
    }

    /// Convert to DateComponents for notification triggers.
    func asDateComponents() -> DateComponents {
        var c = DateComponents()
        c.hour = hour
        c.minute = minute
        return c
    }

    /// Format as "HH:mm" (24h).
    func formatted24h() -> String {
        let hh = String(format: "%02d", hour)
        let mm = String(format: "%02d", minute)
        return "\(hh):\(mm)"
    }
}

// MARK: - Attachments

/// Attachment type: package photo or instructions (photo or PDF).
enum AttachmentKind: String, Codable {
    case packagePhoto
    case instructionPhoto
    case instructionPDF
}

/// Attachment reference: store relative file path (inside app container).
struct AttachmentRef: Codable, Identifiable, Hashable {
    let id: UUID
    let kind: AttachmentKind
    let relativePath: String
    let createdAt: Date

    init(id: UUID = UUID(), kind: AttachmentKind, relativePath: String, createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.relativePath = relativePath
        self.createdAt = createdAt
    }
}

// MARK: - Medication

/// Medication card.
struct Medication: Codable, Identifiable, Hashable {
    let id: UUID

    var name: String                // "Magnesium Citrate"
    var subtitle: String            // "200 mg"
    var category: MedicationCategory

    var expiryDate: Date?           // optional
    var intakeTime: TimeOfDay       // single time for MVP
    var frequency: MedicationFrequency

    /// Attachments: package + instructions.
    var attachments: [AttachmentRef]

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        category: MedicationCategory,
        expiryDate: Date?,
        intakeTime: TimeOfDay,
        frequency: MedicationFrequency,
        attachments: [AttachmentRef] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.category = category
        self.expiryDate = expiryDate
        self.intakeTime = intakeTime
        self.frequency = frequency
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Dose Events (history / calendar / stats)

/// Intake status we log.
enum IntakeStatus: String, Codable {
    case planned
    case taken
    case missed
}

/// A single scheduled dose (the unit for stats).
struct DoseEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let medicationId: UUID

    /// Local scheduled date-time.
    let scheduledAt: Date

    var status: IntakeStatus
    var decidedAt: Date?

    init(
        id: UUID = UUID(),
        medicationId: UUID,
        scheduledAt: Date,
        status: IntakeStatus,
        decidedAt: Date? = nil
    ) {
        self.id = id
        self.medicationId = medicationId
        self.scheduledAt = scheduledAt
        self.status = status
        self.decidedAt = decidedAt
    }
}

// MARK: - App Snapshot (stored in UserDefaults)

/// Stored as a single JSON blob in UserDefaults.
struct AppSnapshot: Codable {
    var medications: [Medication]
    var doseEvents: [DoseEvent]

    init(medications: [Medication] = [], doseEvents: [DoseEvent] = []) {
        self.medications = medications
        self.doseEvents = doseEvents
    }
}
