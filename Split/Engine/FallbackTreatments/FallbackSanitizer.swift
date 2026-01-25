//  Created by Martin Cardozo on 26/08/2025

import Foundation
import Logging

final class FallbackSanitizer: NSObject {
    
    // Allowed: "123.abc", "abc123"
    // Not allowed: "abc.123"
    private static let regexPattern = "^[0-9]+[.a-zA-Z0-9_-]*$|^[a-zA-Z]+[a-zA-Z0-9_-]*$"
    private static let regex = try? NSRegularExpression(pattern: regexPattern)
    
    enum FallbackDiscardReason: Int {
        case flagName
        case treatment
        
        public func toString() -> String {
            switch self {
                case .flagName:
                    return "Invalid flag name (max 100 chars, no spaces)"
                case .treatment:
                    return "Invalid treatment (max 100 chars and comply with \(regexPattern))"
            }
        }
    }
    
    // MARK: Sanitize Global treatment
    static func sanitize(treatment: FallbackTreatment) -> FallbackTreatment? {
        if !isValidTreatment(treatment)  {
            Logger.e("Fallback treatments - Discarded fallback: \(FallbackDiscardReason.treatment.rawValue)")
            return nil
        }
        return treatment
    }
    
    // MARK: Sanitize Flags treatments
    static func sanitize(byFlagFallbacks: [String: FallbackTreatment]) -> [String: FallbackTreatment] {
        
        var sanitizedByFlag: [String: FallbackTreatment] = [:]
        
        for (flag, treatment) in byFlagFallbacks {
            guard isValidFlagName(flag) else {
                Logger.e("Fallback treatments - Discarded flag '\(flag)': \(FallbackDiscardReason.flagName.rawValue)")
                continue
            }
            guard isValidTreatment(treatment) else {
                Logger.e("Fallback treatments - Discarded treatment for flag '\(flag)': \(FallbackDiscardReason.treatment.rawValue)")
                continue
            }
            sanitizedByFlag[flag] = treatment
        }
        return sanitizedByFlag
    }
    
    private static func isValidFlagName(_ name: String) -> Bool {
        name.count <= 100 && !(name.contains(" "))
    }
    
    private static func isValidTreatment(_ fallback: FallbackTreatment) -> Bool {

        // Length constraint
        if fallback.treatment.count > 100 {
            return false
        }
        
        // Regxep (content constraint)
        let range = NSRange(fallback.treatment.startIndex..<fallback.treatment.endIndex, in: fallback.treatment)
        return regex?.firstMatch(in: fallback.treatment, range: range)?.range == range
    }
}
