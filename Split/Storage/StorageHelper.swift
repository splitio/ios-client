//  Created by Martin Cardozo on 15/07/2025

// ⚠️ Don't change to struct. This enum without cases is used as a namespace, and forbids accidental instantiation
enum StorageHelper {

    //@inline(__always)
    static func usesSegments(_ conditions: [Condition]?) -> Bool {
        guard let conditions = conditions else { return false }
        
        for condition in conditions {
            let matchers = condition.matcherGroup?.matchers ?? []
            for matcher in matchers {
                if matcher.matcherType == .inSegment || matcher.matcherType == .inLargeSegment {
                    return true
                }
            }
        }
        return false
    }
}
