import Foundation

let Magic_V4_FFTH_3105: [UInt8] = []
let Magic_V4_FFMAX_3105: [UInt8] = []
let Aim_Body_FFTH_3105: [UInt8] = []
let Aim_Body_FFMAX_3105: [UInt8] = []
let Aim_Neck_V1_FFTH_3105: [UInt8] = []
let Aim_Neck_V1_FFMAX_3105: [UInt8] = []
let Aim_Neck_V2_FFTH_3105: [UInt8] = []
let Aim_Neck_V2_FFMAX_3105: [UInt8] = []

enum EmbeddedPatchLoader {
    static func data(for feature: LocalPatchFeature, game: LocalGameVariant) -> Data? {
        return nil
    }
}

enum PatchAssetLoader {
    static func loadPatchData(for definition: LocalPatchDefinition) -> Data? {
        return nil
    }

    static func exists(for definition: LocalPatchDefinition) -> Bool {
        return false
    }

    static func availableFeatures(for game: LocalGameVariant) -> Set<LocalPatchFeature> {
        return []
    }
}
