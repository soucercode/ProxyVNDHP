import Foundation

enum EmbeddedPatchLoader {

    static func data(
        for feature: LocalPatchFeature,
        game: LocalGameVariant
    ) -> Data? {
        guard let definition = LocalPatchDefinitions.definition(
            for: feature,
            game: game
        ) else {
            return nil
        }

        return PatchAssetLoader.loadPatchData(
            for: definition
        )
    }
}

enum PatchAssetLoader {

    private static let patchDirectory = "Patches"

    // MARK: - Load Patch

    static func loadPatchData(
        for definition: LocalPatchDefinition
    ) -> Data? {

        guard let url = patchURL(
            for: definition
        ) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)

            guard !data.isEmpty else {
                return nil
            }

            return data
        } catch {
            return nil
        }
    }

    // MARK: - Check Exists

    static func exists(
        for definition: LocalPatchDefinition
    ) -> Bool {

        guard let url = patchURL(
            for: definition
        ) else {
            return false
        }

        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return false
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(
                atPath: url.path
            )

            let fileSize =
                attributes[.size] as? NSNumber

            return (fileSize?.intValue ?? 0) > 0
        } catch {
            return false
        }
    }

    // MARK: - Available Features

    static func availableFeatures(
        for game: LocalGameVariant
    ) -> Set<LocalPatchFeature> {

        var result = Set<LocalPatchFeature>()

        let definitions =
            LocalPatchDefinitions.definitions(
                for: game
            )

        for definition in definitions {

            if exists(
                for: definition
            ) {
                result.insert(
                    definition.feature
                )
            }
        }

        return result
    }

    // MARK: - Patch URL

    private static func patchURL(
        for definition: LocalPatchDefinition
    ) -> URL? {

        let fileName =
            definition.resourceName

        // Trường hợp Patches là thư mục thật
        // được đóng trong Bundle.
        if let url = Bundle.main.url(
            forResource: fileName,
            withExtension: "3105",
            subdirectory: patchDirectory
        ) {
            return url
        }

        // Fallback: resource được đưa trực tiếp
        // vào Bundle nhưng không giữ subdirectory.
        if let url = Bundle.main.url(
            forResource: fileName,
            withExtension: "3105"
        ) {
            return url
        }

        return nil
    }
}
