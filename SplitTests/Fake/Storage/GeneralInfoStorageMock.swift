import Foundation
@testable import Split

class GeneralInfoStorageMock: GeneralInfoStorage {

    let queue = DispatchQueue(label: "test", target: .global())
    var updateTimestamp: Int64 = 0
    var rolloutCacheLastClearTimestamp: Int64 = 0

    func getUpdateTimestamp() -> Int64 {
        return updateTimestamp
    }

    func setUpdateTimestamp(timestamp: Int64) {
        updateTimestamp = timestamp
    }

    func getRolloutCacheLastClearTimestamp() -> Int64 {
        return rolloutCacheLastClearTimestamp
    }

    func setRolloutCacheLastClearTimestamp(timestamp: Int64) {
        rolloutCacheLastClearTimestamp = timestamp
    }
}
