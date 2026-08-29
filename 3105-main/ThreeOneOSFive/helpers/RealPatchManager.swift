import Foundation

enum PatchError: Error, LocalizedError {
    case patchNotFound
    case invalidPatch
    case targetNotFound
    case backupFailed
    case applyFailed
    case verifyFailed
    case restoreFailed

    var errorDescription: String? {
        switch self {
        case .patchNotFound: return "Patch file not found"
        case .invalidPatch: return "Patch file is invalid or empty"
        case .targetNotFound: return "Target file not found in container"
        case .backupFailed: return "Failed to backup original file"
        case .applyFailed: return "Failed to apply patch"
        case .verifyFailed: return "Patch verification failed"
        case .restoreFailed: return "Failed to restore original file"
        }
    }
}

struct PatchTransaction {
    let patchData: Data
    let targetURL: URL
    let backupURL: URL
    let originalData: Data?
}

final class RealPatchManager {
    static let shared = RealPatchManager()
    private let fileManager = FileManager.default
    
    // Thư mục backup trong sandbox của ProxyVN
    private var backupRootURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("PatchBackups", isDirectory: true)
    }
    
    private init() {
        try? fileManager.createDirectory(at: backupRootURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Apply Patch
    
    func applyPatch(
        patchData: Data,
        targetURL: URL,
        backupURL: URL? = nil
    ) throws {
        // 1. Kiểm tra dữ liệu patch
        guard !patchData.isEmpty else {
            throw PatchError.invalidPatch
        }
        
        // 2. Đảm bảo thư mục đích tồn tại
        let targetDirectory = targetURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        
        // 3. Backup file gốc (nếu tồn tại)
        let backup = backupURL ?? backupURLFor(targetURL: targetURL)
        if fileManager.fileExists(atPath: targetURL.path) {
            do {
                if fileManager.fileExists(atPath: backup.path) {
                    try fileManager.removeItem(at: backup)
                }
                try fileManager.copyItem(at: targetURL, to: backup)
            } catch {
                throw PatchError.backupFailed
            }
        }
        
        // 4. Ghi patch mới
        do {
            try patchData.write(to: targetURL, options: .atomic)
        } catch {
            // Rollback nếu ghi thất bại
            if fileManager.fileExists(atPath: backup.path) {
                try? fileManager.copyItem(at: backup, to: targetURL)
            }
            throw PatchError.applyFailed
        }
        
        // 5. Verify
        guard fileManager.fileExists(atPath: targetURL.path) else {
            throw PatchError.verifyFailed
        }
        
        let writtenData = try Data(contentsOf: targetURL)
        guard writtenData == patchData else {
            // Rollback nếu verify thất bại
            if fileManager.fileExists(atPath: backup.path) {
                try? fileManager.copyItem(at: backup, to: targetURL)
            }
            throw PatchError.verifyFailed
        }
    }
    
    // MARK: - Restore
    
    func restorePatch(
        targetURL: URL,
        backupURL: URL? = nil
    ) throws {
        let backup = backupURL ?? backupURLFor(targetURL: targetURL)
        
        guard fileManager.fileExists(atPath: backup.path) else {
            throw PatchError.restoreFailed
        }
        
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        
        try fileManager.copyItem(at: backup, to: targetURL)
        
        // Xóa backup sau khi restore thành công
        try? fileManager.removeItem(at: backup)
    }
    
    // MARK: - Helpers
    
    func isPatchApplied(targetURL: URL, patchData: Data) -> Bool {
        guard let currentData = try? Data(contentsOf: targetURL) else { return false }
        return currentData == patchData
    }
    
    func hasBackup(for targetURL: URL) -> Bool {
        let backup = backupURLFor(targetURL: targetURL)
        return fileManager.fileExists(atPath: backup.path)
    }
    
    private func backupURLFor(targetURL: URL) -> URL {
        let fileName = targetURL.lastPathComponent + ".bak"
        return backupRootURL.appendingPathComponent(fileName)
    }
}
