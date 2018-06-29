//
//  MyTaskPOC.swift
//  Split_Example
//
//  Created by Sebastian Arrubia on 4/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Split

class MyTaskOnReady: SplitEventTask {
    var _vc:GetTreatmentViewController
    
    public init(vc:GetTreatmentViewController){
        _vc = vc
        super.init()
        _vc.isEvaluating(active: true)
    }
    
    override public func onPostExecute(client:SplitClientProtocol) -> Void {
        //Do some stuff here at background execution
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
