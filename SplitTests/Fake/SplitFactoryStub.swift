//
//  SplitFactoryStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitFactoryStub: SplitFactory {
    var client: SplitClient
    
    var manager: SplitManager
    
    var version: String
    var apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
        client = SplitClientStub()
        manager = SplitManagerStub()
        version = "0.0.0-stub"
    }
    
    
}
