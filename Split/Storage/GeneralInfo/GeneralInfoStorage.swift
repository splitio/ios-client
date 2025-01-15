import Foundation

protocol GeneralInfoStorage {
    func getUpdateTimestamp() -> Int64
    func setUpdateTimestamp(timestamp: Int64)
    func getRolloutCacheLastClearTimestamp() -> Int64
    func setRolloutCacheLastClearTimestamp(timestamp: Int64)
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
}
