//
//  TreatmentFetcher.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol TreatmentFetcher {
    func fetch(splitName: String) -> String?
    func fetchAll() -> [String:String]?
    func forceRefresh()
}
