//
//  MyTaskOnReadyTimedOut.swift
//  Split_Example
//
//  Created by Sebastian Arrubia on 4/18/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Split

class MyTaskOnReadyTimedOut: SplitEventTask {
    var _vc:ViewController
    
    public init(vc:ViewController){
        _vc = vc
        super.init()
    }
    
    override public func onPostExecute(client:SplitClientProtocol) -> Void {

    }
    
    override public func onPostExecuteView(client:SplitClientProtocol) -> Void {
        _vc.treatmentResult?.text = "SDK_TIMEOUT"
    }
}
