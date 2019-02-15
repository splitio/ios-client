//
//  SplitEventExecutorResources.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

public class SplitEventExecutorResources {
    private var _client: SplitClient?
    
    public init() {}
    
    public func setClient(client: SplitClient) {
        _client = client
    }
    
    public func getClient() -> SplitClient {
        return _client!
    }
}
