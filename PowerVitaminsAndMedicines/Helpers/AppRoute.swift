import Foundation

enum AppRoute: Hashable {
    case medicationDetail(id: UUID)
    case medicationEditor(mode: MedicationEditorMode)

    enum MedicationEditorMode: Hashable {
        case create
        case edit(id: UUID)
    }
}
