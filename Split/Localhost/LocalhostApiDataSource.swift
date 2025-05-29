//
//  LocalhostApiDataSource.swift
//  Split
//
//  Created by Javier Avrudsky on 03/01/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

protocol LocalhostInputDataProducer {
    func update(yaml: String)
    func update(splits: String)
}

class LocalhostApiDataSource: LocalhostDataSource, LocalhostInputDataProducer {
    var loadHandler: IncomingDataHandler?

    func start() {}

    func stop() {}

    func update(yaml: String) {
        loadHandler?(LocalhostParserProvider.parser(for: .yaml).parseContent(yaml))
    }

    func update(splits: String) {
        loadHandler?(LocalhostParserProvider.parser(for: .splits).parseContent(splits))
    }
}
