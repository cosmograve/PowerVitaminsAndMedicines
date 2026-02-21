import Foundation

enum StorageError: Error {
    case encodingFailed
    case decodingFailed
}

final class UserDefaultsStorage {

    nonisolated static let shared = UserDefaultsStorage()

    private let defaults: UserDefaults
    private let key = "power_vitamins_app_snapshot_v1"

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    func load() throws -> AppSnapshot {
        guard let data = defaults.data(forKey: key) else {
            return AppSnapshot()
        }
        do {
            return try decoder.decode(AppSnapshot.self, from: data)
        } catch {
            throw StorageError.decodingFailed
        }
    }

    func save(_ snapshot: AppSnapshot) throws {
        do {
            let data = try encoder.encode(snapshot)
            defaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed
        }
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
