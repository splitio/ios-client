//  Created by Martin Cardozo on 26/08/2025

struct FallbackSanitizer {
    
    enum FallbackDiscardReason: String {
        case flagName = "Invalid flag name (max 100 chars, no spaces)"
        case treatment = "Invalid treatment (max 100 chars)"
    }
    
    static func sanitize(_ config: FallbackConfig) -> FallbackConfig {
        
        // MARK: Global
        let sanitizedGlobal: FallbackTreatment?
        
        if let g = config.global, !isValidTreatment(g) {
            Logger.w("Discarded global fallback: \(FallbackDiscardReason.treatment.rawValue)")
            sanitizedGlobal = nil
        } else {
            sanitizedGlobal = config.global
        }
        
        // MARK: By Flag
        var sanitizedByFlag: [String: FallbackTreatment] = [:]
        
        for (flag, t) in config.byFlag {
            guard isValidFlagName(flag) else {
                Logger.w("Discarded flag '\(flag)': \(FallbackDiscardReason.flagName.rawValue)")
                continue
            }
            guard isValidTreatment(t) else {
                Logger.w("Discarded treatment for flag '\(flag)': \(FallbackDiscardReason.treatment.rawValue)")
                continue
            }
            sanitizedByFlag[flag] = t
        }
        return FallbackConfig(global: sanitizedGlobal, byFlag: sanitizedByFlag)
    }
    
    private static func isValidFlagName(_ name: String) -> Bool {
        name.count <= 100 && !name.contains(" ")
    }
    
    private static func isValidTreatment(_ t: FallbackTreatment) -> Bool {
        t.treatment.count <= 100
    }
}
