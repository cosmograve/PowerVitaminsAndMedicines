import Foundation


enum MedicationCategory: String, Codable, CaseIterable, Identifiable {
    case vitamins
    case medicines
    case supplements

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vitamins: return "Vitamins"
        case .medicines: return "Medicines"
        case .supplements: return "Supplements"
        }
    }

    var icon: String {
        switch self {
        case .vitamins: return "💊"
        case .medicines: return "💊"
        case .supplements: return "💊"
        }
    }
}


enum MedicationFrequency: Codable, Equatable, Hashable {
    case daily
    case everyOtherDay(anchor: Date)
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
            let w = calendar.component(.weekday, from: day)
            return w >= 2 && w <= 6

        case .everyOtherDay(let anchor):
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


struct TimeOfDay: Codable, Hashable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }

    init(date: Date, calendar: Calendar = .current) {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: comps.hour ?? 0, minute: comps.minute ?? 0)
    }

    func asDateComponents() -> DateComponents {
        var c = DateComponents()
        c.hour = hour
        c.minute = minute
        return c
    }

    func formatted24h() -> String {
        let hh = String(format: "%02d", hour)
        let mm = String(format: "%02d", minute)
        return "\(hh):\(mm)"
    }
}


enum AttachmentKind: String, Codable {
    case packagePhoto
    case instructionPhoto
    case instructionPDF
}

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


struct Medication: Codable, Identifiable, Hashable {
    let id: UUID

    var name: String
    var subtitle: String
    var category: MedicationCategory

    var expiryDate: Date?
    var intakeTime: TimeOfDay
    var frequency: MedicationFrequency
    var notificationsEnabled: Bool

    var attachments: [AttachmentRef]

    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case subtitle
        case category
        case expiryDate
        case intakeTime
        case frequency
        case notificationsEnabled
        case attachments
        case createdAt
        case updatedAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        category: MedicationCategory,
        expiryDate: Date?,
        intakeTime: TimeOfDay,
        frequency: MedicationFrequency,
        notificationsEnabled: Bool = true,
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
        self.notificationsEnabled = notificationsEnabled
        self.attachments = attachments
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        category = try container.decode(MedicationCategory.self, forKey: .category)
        expiryDate = try container.decodeIfPresent(Date.self, forKey: .expiryDate)
        intakeTime = try container.decode(TimeOfDay.self, forKey: .intakeTime)
        frequency = try container.decode(MedicationFrequency.self, forKey: .frequency)
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        attachments = try container.decodeIfPresent([AttachmentRef].self, forKey: .attachments) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(category, forKey: .category)
        try container.encode(expiryDate, forKey: .expiryDate)
        try container.encode(intakeTime, forKey: .intakeTime)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}


enum IntakeStatus: String, Codable {
    case planned
    case taken
    case missed
}

struct DoseEvent: Codable, Identifiable, Hashable {
    let id: UUID
    let medicationId: UUID

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


struct AppSnapshot: Codable {
    var medications: [Medication]
    var doseEvents: [DoseEvent]

    init(medications: [Medication] = [], doseEvents: [DoseEvent] = []) {
        self.medications = medications
        self.doseEvents = doseEvents
    }
}
