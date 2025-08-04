import Foundation

protocol RolloutCacheManager {
    func validateCache(listener: (() -> Void))
}

class DefaultRolloutCacheManager: RolloutCacheManager {
    private let kMinCacheClearDays = 1
    private let generalInfoStorage: GeneralInfoStorage
    private let rolloutCacheConfiguration: RolloutCacheConfiguration
    private let rolloutDefinitionsCache: [RolloutDefinitionsCache]

    init(generalInfoStorage: GeneralInfoStorage,
         rolloutCacheConfiguration: RolloutCacheConfiguration,
         storages: RolloutDefinitionsCache...) {
        self.generalInfoStorage = generalInfoStorage
        self.rolloutCacheConfiguration = rolloutCacheConfiguration
        self.rolloutDefinitionsCache = storages
    }

    func validateCache(listener: (() -> Void)) {
        
        defer {
            listener()
        }

        if shouldClear() {
            clear()
        }
    }

    private func shouldClear() -> Bool {
        let lastUpdateTimestamp = generalInfoStorage.getUpdateTimestamp()
        let daysSinceLastUpdate = Date.secondsToDays(seconds: Date.now() - lastUpdateTimestamp)

        if lastUpdateTimestamp > 0 && daysSinceLastUpdate >= rolloutCacheConfiguration.expirationDays {
            Logger.v("Clearing rollout definitions cache due to expiration")
            return true
        } else if rolloutCacheConfiguration.clearOnInit {
            let lastCacheClearTimestamp = generalInfoStorage.getRolloutCacheLastClearTimestamp()
            if lastCacheClearTimestamp < 1 { // 0 is default value for rollout cache timestamp
                return true
            }
            let daysSinceCacheClear = Date.secondsToDays(seconds: Date.now() - lastCacheClearTimestamp)

            // don't clear too soon
            if daysSinceCacheClear >= kMinCacheClearDays {
                Logger.v("Forcing rollout definitions cache clear")
                return true
            } else {
                Logger.v("Rollout definitions cache was cleared recently. Skipping")
            }
        }

        return false
    }

    private func clear() {
        for cache in rolloutDefinitionsCache {
            cache.clear()
        }
        generalInfoStorage.setRolloutCacheLastClearTimestamp(timestamp: Date.now())
        Logger.v("Rollout definitions cache cleared")
    }
}
