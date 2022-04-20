//
//  TreatmentManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 22-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol TreatmentManager {
    func getTreatment(_ splitName: String, attributes: [String: Any]?) -> String
    func getTreatmentWithConfig(_ splitName: String, attributes: [String: Any]?) -> SplitResult
    func getTreatments(splits: [String], attributes: [String: Any]?) -> [String: String]
    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?) -> [String: SplitResult]
    func destroy()
}
