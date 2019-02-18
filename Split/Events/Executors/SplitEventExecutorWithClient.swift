//
//  SplitEventExecutorWithClient.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

class SplitEventExecutorWithClient: SplitEventExecutorProtocol {
    
    private var _task: SplitEventTask
    private var _client: SplitClient
    
    public init(task:SplitEventTask, client:SplitClient) {
        _task = task
        _client = client
    }
    
    public func execute(){
        DispatchQueue.global().async {
            // Background thread
            self._task.onPostExecute(client: self._client)
            DispatchQueue.main.async(execute: {
                // UI Updates
                self._task.onPostExecuteView(client: self._client)
            })
        }
    }
    
}
