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
        _vc.isEvaluating(active: true)
    }
    
    override public func onPostExecute() -> Void {

    }
    
    override public func onPostExecuteView(client:SplitClientProtocol) -> Void {
                
        var attributes: [String:Any]?
        if let json = _vc.param1?.text {
            attributes = _vc.convertToDictionary(text: json)
        }
        
        let treatment = client.getTreatment((_vc.splitName?.text)!, attributes: attributes)
        _vc.treatmentResult?.text = treatment
        _vc.isEvaluating(active: false)
    }
}
