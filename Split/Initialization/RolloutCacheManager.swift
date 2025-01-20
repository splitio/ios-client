import Foundation

protocol RolloutCacheManager {
    func validateCache(listener: (() -> Void)?)
}

class DefaultRolloutCacheManager: RolloutCacheManager {
    private let kMinCacheClearDays = 1
    private let generalInfoStorage: GeneralInfoStorage
    private let splitsStorage: SplitsStorage
    private let mySegmentsStorage: MySegmentsStorage
    private let myLargeSegmentsStorage: MySegmentsStorage
    
    init(generalInfoStorage: GeneralInfoStorage, splitsStorage: SplitsStorage, mySegmentsStorage: MySegmentsStorage, myLargeSegmentsStorage: MySegmentsStorage) {
        self.generalInfoStorage = generalInfoStorage
        self.splitsStorage = splitsStorage
        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = myLargeSegmentsStorage
    }
    
    func validateCache(listener: (() -> Void)?) {
        // TODO: implementation
    }
}
