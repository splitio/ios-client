//
//  GeneralInfoDaoStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

@testable import Split
import Foundation

class GeneralInfoDaoStub: GeneralInfoDao {

    var updatedString = [String: String]()
    var updatedLong = [String: Int64]()

    func update(info: GeneralInfo, stringValue: String) {
        updatedString[info.rawValue] = stringValue
    }

    func update(info: GeneralInfo, longValue: Int64) {
        updatedLong[info.rawValue] = longValue
    }

    func stringValue(info: GeneralInfo) -> String? {
        return updatedString[info.rawValue]
    }

    func longValue(info: GeneralInfo) -> Int64? {
        return updatedLong[info.rawValue]
    }

    func delete(info: GeneralInfo) {
        updatedString.removeValue(forKey: info.rawValue)
        updatedLong.removeValue(forKey: info.rawValue)
    }
}
