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
        case .patchNotFound: return "Không tìm thấy file patch"
        case .invalidPatch: return "File patch bị hỏng hoặc rỗng"
        case .targetNotFound: return "Không tìm thấy game hoặc file đích"
        case .backupFailed: return "Sao lưu file gốc thất bại"
        case .applyFailed: return "Áp dụng patch thất bại"
        case .verifyFailed: return "Xác minh patch thất bại"
        case .restoreFailed: return "Khôi phục file gốc thất bại"
        }
    }
}

final class RealPatchManager {
    static let shared = RealPatchManager()
    private let fileManager = FileManager.default
    
    private var backupRootURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("PatchBackups", isDirectory: true)
    }
    
    private init() {
        try? fileManager.createDirectory(at: backupRootURL, withIntermediateDirectories: true)
    }
    
    // MARK: - ÁP DỤNG PATCH VÀO GAME
    
    func applyPatch(
        patchData: Data,
        bundleID: String,
        relativePath: String
    ) throws {
        // === THÊM SANDBOX ESCAPE ===
        let selfProc = proc_self()
        _ = sandbox_escape(selfProc)
        _ = sandbox_elevate_to_root(selfProc)
        // ============================
        
        // 1. Lấy container path của game
        var error: NSString?
        guard let containerPath = MCMActivateContainerPath(2, bundleID, false, &error) else {
            let detail = error.map { String($0) } ?? "unknown"
            throw PatchError.targetNotFound
        }
        
        let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)
        let targetURL = containerURL.appendingPathComponent(relativePath)
        
        // 2. Kiểm tra dữ liệu patch
        guard !patchData.isEmpty else {
            throw PatchError.invalidPatch
        }
        
        // 3. Đảm bảo thư mục đích tồn tại
        let targetDirectory = targetURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        
        // 4. Backup file gốc (nếu tồn tại)
        let backupURL = backupURLFor(targetURL: targetURL)
        if fileManager.fileExists(atPath: targetURL.path) {
            do {
                if fileManager.fileExists(atPath: backupURL.path) {
                    try fileManager.removeItem(at: backupURL)
                }
                try fileManager.copyItem(at: targetURL, to: backupURL)
            } catch {
                throw PatchError.backupFailed
            }
        }
        
        // 5. GHI ĐÈ PATCH
        do {
            try patchData.write(to: targetURL, options: .atomic)
        } catch {
            // Rollback nếu ghi thất bại
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.copyItem(at: backupURL, to: targetURL)
            }
            throw PatchError.applyFailed
        }
        
        // 6. Xác minh
        guard fileManager.fileExists(atPath: targetURL.path) else {
            throw PatchError.verifyFailed
        }
        
        let writtenData = try Data(contentsOf: targetURL)
        guard writtenData == patchData else {
            // Rollback nếu verify thất bại
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.copyItem(at: backupURL, to: targetURL)
            }
            throw PatchError.verifyFailed
        }
    }
    
    // MARK: - KHÔI PHỤC FILE GỐC
    
    func restorePatch(
        bundleID: String,
        relativePath: String
    ) throws {
        // === THÊM SANDBOX ESCAPE ===
        let selfProc = proc_self()
        _ = sandbox_escape(selfProc)
        _ = sandbox_elevate_to_root(selfProc)
        // ============================
        
        var error: NSString?
        guard let containerPath = MCMActivateContainerPath(2, bundleID, false, &error) else {
            let detail = error.map { String($0) } ?? "unknown"
            throw PatchError.targetNotFound
        }
        
        let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)
        let targetURL = containerURL.appendingPathComponent(relativePath)
        let backupURL = backupURLFor(targetURL: targetURL)
        
        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw PatchError.restoreFailed
        }
        
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        
        try fileManager.copyItem(at: backupURL, to: targetURL)
        try? fileManager.removeItem(at: backupURL)
    }
    
    // MARK: - KIỂM TRA TRẠNG THÁI
    
    func isPatchApplied(
        bundleID: String,
        relativePath: String,
        patchData: Data
    ) -> Bool {
        guard let containerPath = MCMActivateContainerPath(2, bundleID, false, nil) else {
            return false
        }
        let containerURL = URL(fileURLWithPath: containerPath, isDirectory: true)
        let targetURL = containerURL.appendingPathComponent(relativePath)
        guard let currentData = try? Data(contentsOf: targetURL) else { return false }
        return currentData == patchData
    }
    
    private func backupURLFor(targetURL: URL) -> URL {
        let fileName = targetURL.lastPathComponent + ".bak"
        return backupRootURL.appendingPathComponent(fileName)
    }
}
