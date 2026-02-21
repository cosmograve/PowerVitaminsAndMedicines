import Foundation
import UIKit

/// Errors for attachment storage operations.
enum AttachmentStorageError: Error {
    case cannotCreateBaseDirectory
    case cannotWriteFile
    case fileNotFound
}

/// Stores photos/PDFs locally in Application Support/Attachments.
final class LocalAttachmentsManager {

    static let shared = LocalAttachmentsManager()

    private let fileManager: FileManager
    private let baseFolderName = "Attachments"

    private init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Application Support directory URL.
    private func applicationSupportURL() throws -> URL {
        guard let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw AttachmentStorageError.cannotCreateBaseDirectory
        }
        return url
    }

    /// Attachments folder URL: Application Support/Attachments
    private func attachmentsDirectoryURL() throws -> URL {
        let base = try applicationSupportURL()
        let dir = base.appendingPathComponent(baseFolderName, isDirectory: true)

        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                throw AttachmentStorageError.cannotCreateBaseDirectory
            }
        }
        return dir
    }

    /// Save a UIImage as JPEG into local storage.
    /// - Returns: relativePath like "Attachments/uuid.jpg"
    func saveJPEG(image: UIImage, compressionQuality: CGFloat = 0.9) throws -> String {
        let dir = try attachmentsDirectoryURL()
        let filename = "\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw AttachmentStorageError.cannotWriteFile
        }

        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw AttachmentStorageError.cannotWriteFile
        }

        return "\(baseFolderName)/\(filename)"
    }

    /// Save arbitrary data (e.g. PDF).
    /// - Returns: relativePath like "Attachments/uuid.pdf"
    func saveData(_ data: Data, fileExtension: String) throws -> String {
        let dir = try attachmentsDirectoryURL()
        let safeExt = fileExtension.lowercased()
        let filename = "\(UUID().uuidString).\(safeExt)"
        let url = dir.appendingPathComponent(filename)

        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            throw AttachmentStorageError.cannotWriteFile
        }

        return "\(baseFolderName)/\(filename)"
    }

    /// Get absolute URL by relative path.
    func url(forRelativePath relativePath: String) throws -> URL {
        let base = try applicationSupportURL()
        return base.appendingPathComponent(relativePath, isDirectory: false)
    }

    /// Delete an attachment file.
    func delete(relativePath: String) throws {
        let url = try url(forRelativePath: relativePath)
        guard fileManager.fileExists(atPath: url.path) else {
            throw AttachmentStorageError.fileNotFound
        }
        try fileManager.removeItem(at: url)
    }
}
