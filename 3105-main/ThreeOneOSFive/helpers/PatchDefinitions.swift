import Foundation

enum LocalGameVariant: String, CaseIterable, Identifiable {
    case freeFire = "com.dts.freefireth"
    case freeFireMax = "com.dts.freefiremax"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .freeFire:
            return "Free Fire"
        case .freeFireMax:
            return "Free Fire Max"
        }
    }

    var iconAssetName: String {
        switch self {
        case .freeFire:
            return "FreeFire"
        case .freeFireMax:
            return "FreeFireMax"
        }
    }

    var patchRelativePath: String {
        "Documents/contentcache/Compulsory/ios/gameassetbundles/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"
    }
}

enum LocalPatchFeature: String, CaseIterable, Identifiable {
    case aimBody = "Proxy Aim Body"
    case aimNeckV1 = "Proxy Aim Neck V1"
    case aimNeckV2 = "Proxy Aim Neck V2"
    case aimDrag = "Proxy Aim Drag"
    case magicV4 = "Magic V4"

    var id: String { rawValue }
}

struct LocalPatchDefinition: Identifiable {
    let id: String
    let feature: LocalPatchFeature
    let game: LocalGameVariant
    let resourceName: String
    let relativePath: String

    var bundleID: String {
        game.rawValue
    }
}

enum LocalPatchDefinitions {

    static let patchRelativePath =
        "Documents/contentcache/Compulsory/ios/gameassetbundles/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D"

    static let all: [LocalPatchDefinition] = [

        // Free Fire
        .init(
            id: "ffth.body",
            feature: .aimBody,
            game: .freeFire,
            resourceName: "Aim Body FFTH",
            relativePath: patchRelativePath
        ),

        .init(
            id: "ffth.v1",
            feature: .aimNeckV1,
            game: .freeFire,
            resourceName: "Aim Neck V1 FFTH",
            relativePath: patchRelativePath
        ),

        .init(
            id: "ffth.v2",
            feature: .aimNeckV2,
            game: .freeFire,
            resourceName: "Aim Neck V2 FFTH",
            relativePath: patchRelativePath
        ),

        .init(
            id: "ffth.aimDrag",
            feature: .aimDrag,
            game: .freeFire,
            resourceName: "Aim Drag FFTH",
            relativePath: patchRelativePath
        ),

        .init(
            id: "ffth.magic",
            feature: .magicV4,
            game: .freeFire,
            resourceName: "Magic V4 FFTH",
            relativePath: patchRelativePath
        ),

        // Free Fire MAX
        .init(
            id: "ffmax.body",
            feature: .aimBody,
            game: .freeFireMax,
            resourceName: "Aim Body FFMAX",
            relativePath: patchRelativePath
        ),

        .init(
            id: "ffmax.v1",
            feature: .aimNeckV1,
            game: .freeFireMax,
            resourceName: "Aim Neck V1 FFMAX",
            relativePath: patchRelativePath
        ),

        .init(
            id: "ffmax.v2",
            feature: .aimNeckV2,
            game: .freeFireMax,
            resourceName: "Aim Neck V2 FFMAX",
            relativePath: patchRelativePath
        ),

        .init(
            id: "ffmax.aimDrag",
            feature: .aimDrag,
            game: .freeFireMax,
            resourceName: "Aim Drag FFMAX",
            relativePath: patchRelativePath
        ),

        .init(
            id: "ffmax.magic",
            feature: .magicV4,
            game: .freeFireMax,
            resourceName: "Magic V4 FFMAX",
            relativePath: patchRelativePath
        )
    ]

    static func definition(
        for feature: LocalPatchFeature,
        game: LocalGameVariant
    ) -> LocalPatchDefinition? {
        all.first {
            $0.feature == feature &&
            $0.game == game
        }
    }

    static func definitions(
        for game: LocalGameVariant
    ) -> [LocalPatchDefinition] {
        all.filter {
            $0.game == game
        }
    }
}
