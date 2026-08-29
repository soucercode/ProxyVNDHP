import Foundation

enum PatchError: LocalizedError {
    case patchNotFound
    case invalidPatch
    case targetNotFound
    case backupFailed
    case applyFailed
    case verifyFailed

    var errorDescription: String? {
        switch self {
        case .patchNotFound:
            return "Patch not found / Không tìm thấy patch"
        case .invalidPatch:
            return "Invalid patch / Patch không hợp lệ"
        case .targetNotFound:
            return "Target not found / Không tìm thấy file đích"
        case .backupFailed:
            return "Backup failed / Sao lưu thất bại"
        case .applyFailed:
            return "Apply failed / Áp dụng thất bại"
        case .verifyFailed:
            return "Verification failed / Kiểm tra thất bại"
        }
    }
}

final class RealPatchManager {

    static let shared = RealPatchManager()

    private let fileManager = FileManager.default

    private init() {}

    // Sandbox của CHÍNH ProxyVN
    private var documentsURL: URL {
        fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    func applyPatch(
        patchURL: URL,
        targetURL: URL,
        backupURL: URL
    ) throws {

        guard fileManager.fileExists(
            atPath: patchURL.path
        ) else {
            throw PatchError.patchNotFound
        }

        let patchData = try Data(contentsOf: patchURL)

        guard !patchData.isEmpty else {
            throw PatchError.invalidPatch
        }

        // Backup file hiện tại
        if fileManager.fileExists(
            atPath: targetURL.path
        ) {
            do {
                if fileManager.fileExists(
                    atPath: backupURL.path
                ) {
                    try fileManager.removeItem(
                        at: backupURL
                    )
                }

                try fileManager.copyItem(
                    at: targetURL,
                    to: backupURL
                )
            } catch {
                throw PatchError.backupFailed
            }
        }

        // Đảm bảo thư mục đích tồn tại
        let directory = targetURL.deletingLastPathComponent()

        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        // Ghi file mới
        do {
            try patchData.write(
                to: targetURL,
                options: .atomic
            )
        } catch {
            throw PatchError.applyFailed
        }

        // Verify
        guard fileManager.fileExists(
            atPath: targetURL.path
        ) else {
            throw PatchError.verifyFailed
        }

        let resultData = try Data(
            contentsOf: targetURL
        )

        guard resultData == patchData else {
            throw PatchError.verifyFailed
        }
    }

    func rollback(
        targetURL: URL,
        backupURL: URL
    ) throws {

        guard fileManager.fileExists(
            atPath: backupURL.path
        ) else {
            throw PatchError.backupFailed
        }

        if fileManager.fileExists(
            atPath: targetURL.path
        ) {
            try fileManager.removeItem(
                at: targetURL
            )
        }

        try fileManager.copyItem(
            at: backupURL,
            to: targetURL
        )
    }
}
