//
//  UniqueKeysDaoStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 17-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class UniqueKeyDaoStub: UniqueKeyDao {
    var features =  [String: [String]]()
    func getBy(userKey: String) -> [String] {
        return features[userKey] ?? []
    }
    
    func update(userKey: String, featureList: [String]) {
        features[userKey] = featureList
    }
}
