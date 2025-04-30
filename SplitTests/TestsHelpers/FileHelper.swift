//
//  FileHelper.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 11/16/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
@testable import Split

class FileHelper {
    static func readDataFromFile(sourceClass: Any, name: String,  type fileType: String)-> String? {
        
        guard let filepath = Bundle(for: type(of: sourceClass) as! AnyClass).path(forResource: name, ofType: fileType) else {
            return nil
        }

        do {
            return try String(contentsOfFile: filepath, encoding: .utf8)
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }

    static func loadFileData(sourceClass: Any, name: String,  type fileType: String)-> Data? {

        guard let filepath = Bundle(for: type(of: sourceClass) as! AnyClass).path(forResource: name, ofType: fileType) else {
            return nil
        }

        let uri = URL(fileURLWithPath: filepath)
        do {
            return try Data(contentsOf: uri)
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }

    static func loadSplitChangeFile(sourceClass: Any, fileName: String) -> SplitChange? {
        if let file = FileHelper.readDataFromFile(sourceClass: sourceClass, name: fileName, type: "json"),
           let change = try? Json.decodeFrom(json: file, to: TargetingRulesChange.self) {
            return change.featureFlags
        }
        return nil
    }
}
