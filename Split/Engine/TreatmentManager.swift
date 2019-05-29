//
//  TreatmentManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 27/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol TreatmentManager {
    func getTreatmentWithConfig(_ split: String, attributes: [String : Any]?, isSdkReadyEventTriggered: Bool) -> SplitResult
    func getTreatment(_ split: String, attributes: [String : Any]?, isSdkReadyEventTriggered: Bool) -> String
    func getTreatments(splits: [String], attributes:[String:Any]?, isSdkReadyEventTriggered: Bool) ->  [String:String]
    func getTreatmentsWithConfig(splits: [String], attributes:[String:Any]?, isSdkReadyEventTriggered: Bool) ->  [String:SplitResult]
}
