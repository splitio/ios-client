//
//  SplitEventActionTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 7/6/18.
//

import Foundation

class SplitEventActionTask: SplitEventTask {
    
    var eventHandler: SplitAction!
    
    override private init(){
        super.init()
    }
    
    convenience init(action: @escaping SplitAction){
        self.init()
        eventHandler = action
    }
    
    override func onPostExecute(client:SplitClient) -> Void {
        // Do nothing
    }
    
    override func onPostExecuteView(client:SplitClient) -> Void {
        eventHandler()
    }
}
