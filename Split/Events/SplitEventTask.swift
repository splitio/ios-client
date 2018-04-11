//
//  SplitEventTask.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/11/18.
//

import Foundation

open class SplitEventTask {
    
    public init(){}
    
    open func onPostExecute() -> Void {
        print("**** ERROR running superclass.onPostExecute")
    }
    
    open func onPostExecuteView(client:SplitClientProtocol) -> Void {
        print("**** ERROR running superclass.onPostExecuteView")
    }
}
