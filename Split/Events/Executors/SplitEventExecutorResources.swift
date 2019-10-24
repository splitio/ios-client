//
//  SplitEventExecutorResources.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

class SplitEventExecutorResources {
    private weak var _client: SplitClient?

    init() {}

    func setClient(client: SplitClient) {
        _client = client
    }

    func getClient() -> SplitClient? {
        return _client
    }
}
