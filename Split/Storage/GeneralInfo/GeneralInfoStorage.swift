import Foundation

protocol GeneralInfoStorage {
    func getUpdateTimestamp() -> Int64
    func setUpdateTimestamp(timestamp: Int64)
    func getRolloutCacheLastClearTimestamp() -> Int64
    func setRolloutCacheLastClearTimestamp(timestamp: Int64)
    func getSplitsFilterQueryString() -> String
    func setSplitsFilterQueryString(filterQueryString: String)
    func getFlagSpec() -> String
    func setFlagSpec(flagsSpec: String)
    
    // Rule based segments methods
    func getRuleBasedSegmentsChangeNumber() -> Int64
    func setRuleBasedSegmentsChangeNumber(changeNumber: Int64)

    // Proxy handling methods
    func getLastProxyUpdateTimestamp() -> Int64
    func setLastProxyUpdateTimestamp(_ timestamp: Int64)
}

class DefaultGeneralInfoStorage: GeneralInfoStorage {

    private let generalInfoDao: GeneralInfoDao

    init(generalInfoDao: GeneralInfoDao) {
        self.generalInfoDao = generalInfoDao
    }

    convenience init(database: SplitDatabase) {
        self.init(generalInfoDao: database.generalInfoDao)
    }

    func getUpdateTimestamp() -> Int64 {
        return generalInfoDao.longValue(info: .splitsUpdateTimestamp) ?? 0
    }

    func setUpdateTimestamp(timestamp: Int64) {
        generalInfoDao.update(info: .splitsUpdateTimestamp, longValue: timestamp)
    }

    func getRolloutCacheLastClearTimestamp() -> Int64 {
        return generalInfoDao.longValue(info: .rolloutCacheLastClearTimestamp) ?? 0
    }

    func setRolloutCacheLastClearTimestamp(timestamp: Int64) {
        generalInfoDao.update(info: .rolloutCacheLastClearTimestamp, longValue: timestamp)
    }

    func getSplitsFilterQueryString() -> String {
        return generalInfoDao.stringValue(info: .splitsFilterQueryString) ?? ""
    }

    func setSplitsFilterQueryString(filterQueryString: String) {
        generalInfoDao.update(info: .splitsFilterQueryString, stringValue: filterQueryString)
    }

    func getFlagSpec() -> String {
        return generalInfoDao.stringValue(info: .flagsSpec) ?? ""
    }

    func setFlagSpec(flagsSpec: String) {
        generalInfoDao.update(info: .flagsSpec, stringValue: flagsSpec)
    }

    func getRuleBasedSegmentsChangeNumber() -> Int64 {
        return generalInfoDao.longValue(info: .ruleBasedSegmentsChangeNumber) ?? -1
    }

    func setRuleBasedSegmentsChangeNumber(changeNumber: Int64) {
        generalInfoDao.update(info: .ruleBasedSegmentsChangeNumber, longValue: changeNumber)
    }

    func getLastProxyUpdateTimestamp() -> Int64 {
        return generalInfoDao.longValue(info: .lastProxyUpdateTimestamp) ?? 0
    }

    func setLastProxyUpdateTimestamp(_ timestamp: Int64) {
        generalInfoDao.update(info: .lastProxyUpdateTimestamp, longValue: timestamp)
    }
}
