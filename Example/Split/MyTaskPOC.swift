//
//  MyTaskPOC.swift
//  Split_Example
//
//  Created by Sebastian Arrubia on 4/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Split

class MyTaskPOC: SplitEventTask {
    var _vc:ViewController
    var _d: String
    
    public init(vc:ViewController){
        _vc = vc
        _d = " - INIT"
        super.init()
    }
    
    override public func onPostExecute() -> Void {
        _d += " - onPostExecute"
    }
    
    override public func onPostExecuteView(client:SplitClientProtocol) -> Void {
        
        var attributes: [String:Any]?
        if let json = _vc.param1?.text {
            attributes = _vc.convertToDictionary(text: json)
        }
        
        let treatment = client.getTreatment((_vc.splitName?.text)!, attributes: attributes)
        _vc.treatmentResult?.text = treatment + _d
    }
}
