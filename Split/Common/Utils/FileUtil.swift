//
//  FileUtil.swift
//  Split
//
//  Created by Javier Avrudsky on 04/07/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

// FileHelper
enum FileUtil {
    static func copySourceFile(name: String, type: String, fileStorage: FileStorage, bundle: Bundle) -> Bool {
        guard let fileContent = loadFile(name: name, type: type, bundle: bundle) else {
            return false
        }
        fileStorage.write(fileName: "\(name).\(type)", content: fileContent)
        return true
    }

    static func loadFile(name fileName: String, type fileType: String, bundle: Bundle) -> String? {
        var fileContent: String?
        if let filepath = bundle.path(forResource: fileName, ofType: fileType) {
            do {
                fileContent = try String(contentsOfFile: filepath, encoding: .utf8)
            } catch {
                Logger.e("Could not load file: \(filepath)")
            }
        }
        return fileContent
    }

    static func loadFileData(name: String, type fileType: String, bundle: Bundle) -> Data? {
        guard let filepath = bundle.path(forResource: name, ofType: fileType) else {
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
}
