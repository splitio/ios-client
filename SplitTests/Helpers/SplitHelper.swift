//
//  SplitHelper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17/12/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitHelper {

    func loadSplitFromFile(name: String) -> Split? {
        var split: Split?
        do {
            split = try JSON.encodeFrom(json: FileHelper.readDataFromFile(sourceClass: self, name: name, type: "json")!, to: Split.self)
        } catch {
            print("Error loading split from file \(name)")
        }
        return split
    }

}
