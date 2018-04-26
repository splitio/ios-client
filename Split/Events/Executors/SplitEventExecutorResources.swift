//
//  SplitEventExecutorResources.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

public class SplitEventExecutorResources {
    private var _client: SplitClientProtocol?
    
    public init() {}
    
    public func setClient(client: SplitClientProtocol) {
        _client = client
    }
    
    public func getClient() -> SplitClientProtocol {
        return _client!
    }
}
