//
//  SplitEventTask.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/11/18.
//

import Foundation

open class SplitEventTask {
    
    public init(){}
    
    open func onPostExecute(client:SplitClientProtocol) -> Void {
        debugPrint("* running superclass.onPostExecute. This method should be override by developers")
    }
    
    open func onPostExecuteView(client:SplitClientProtocol) -> Void {
        debugPrint("* running superclass.onPostExecuteView. This method should be override by developers")
    }
}
