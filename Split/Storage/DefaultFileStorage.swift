//
//  FileStorage.swift
//  Split
//
//  Created by Natalia  Stele on 04/12/2017.
//

import Foundation

class DefaultFileStorage: FileStorage {
    var dataFolderUrl: URL?
    let dataFolderName: String

    init(dataFolderName: String) {
        self.dataFolderName = dataFolderName
    }

    func read(fileName: String) -> String? {
        if let dataFolderUrl = getDataFolder() {
            let fileURL = dataFolderUrl.appendingPathComponent(fileName)
            return try? String(contentsOf: fileURL, encoding: .utf8)
        }
        return nil
    }

    func write(fileName: String, content: String?) {
        if let dataFolderUrl = getDataFolder() {
            do {
                let fileURL = dataFolderUrl.appendingPathComponent(fileName)

                if let data = content {
                    try data.write(to: fileURL, atomically: false, encoding: .utf8)
                    Logger.d("Wrote file \(fileName)")
                }
            } catch {
                Logger.e("File Storage - write: " + error.localizedDescription)
            }
        }
    }

    func delete(fileName: String) {
        delete(elementId: fileName)
    }

    func delete(elementId: String) {
        if let dataFolderUrl = getDataFolder() {
            do {
                let fileURL = dataFolderUrl.appendingPathComponent(elementId)
                try FileManager.default.removeItem(at: fileURL)
            } catch {}
        }
    }

    func getAllIds() -> [String]? {
        if let dataFolderUrl = getDataFolder() {
            let docs = dataFolderUrl.path
            return try? FileManager.default.contentsOfDirectory(atPath: docs)
        }
        return nil
    }

    private func getDataFolder() -> URL? {
        if dataFolderUrl != nil {
            return dataFolderUrl
        }

        let fileManager = FileManager.default
        do {
            let cachesDirectory = try fileManager.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false)
            dataFolderUrl = cachesDirectory.appendingPathComponent(dataFolderName)
            createDataFolderIfNecessary()
        } catch {
            dataFolderUrl = nil
        }
        return dataFolderUrl
    }

    private func createDataFolderIfNecessary() {
        let fileManager = FileManager.default
        if let dataFolderUrl = dataFolderUrl, !fileManager.fileExists(atPath: dataFolderUrl.path) {
            do {
                try fileManager.createDirectory(at: dataFolderUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Logger.e("File Storage - could not create data folder: " + dataFolderUrl.lastPathComponent)
            }
        }
    }
}
