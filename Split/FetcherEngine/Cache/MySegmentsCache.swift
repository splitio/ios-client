//
//  MySegmentsCache.swift
//  Split
//
//  Created by Natalia  Stele on 07/12/2017.
//

import Foundation

/// ** MySegmentsCache **
/// Handles My Segments Cache by loading my segments for
/// a given matching key from disk into memory when the class is instantiated.
/// In memory segments are updated each time new information is retrieved
/// from the server and it is saved to disk when application goes to background.
/// In order to separate segments from different matching keys
/// there is one file per each one of them.

class MySegmentsCache: MySegmentsCacheProtocol {

    private struct MySegmentsFile: Codable {
        var matchingKey: String
        var segments: [String]
    }

    private let kMySegmentsFileNamePrefix  = "SPLITIO.mySegments"
    private var fileStorage: FileStorageProtocol
    private var inMemoryCache: InMemoryMySegmentsCache!
    private var matchingKey: String

    init(matchingKey: String, fileStorage: FileStorageProtocol) {
        self.matchingKey = matchingKey
        self.fileStorage = fileStorage
        self.inMemoryCache = initialInMemoryCache()
        NotificationHelper.instance.addObserver(for: AppNotification.didEnterBackground) {
            DispatchQueue.global().async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.saveSegments()
            }
        }
    }

    func setSegments(_ segments: [String]) {
        inMemoryCache.setSegments(segments)
    }

    func removeSegments() {
        inMemoryCache.removeSegments()
    }

    func getSegments() -> [String] {
        return inMemoryCache.getSegments()
    }

    func isInSegments(name: String) -> Bool {
        return inMemoryCache.isInSegments(name: name)
    }

    func clear() {
        inMemoryCache.clear()
    }
}

// MARK: Private
extension MySegmentsCache {
    private func fileNameForCurrentMatchingKey() -> String {
        return "\(kMySegmentsFileNamePrefix)_\(matchingKey)"
    }

    private func initialInMemoryCache() -> InMemoryMySegmentsCache {
        var inMemoryCache = InMemoryMySegmentsCache(segments: Set<String>())
        guard let jsonContent = fileStorage.read(fileName: fileNameForCurrentMatchingKey()) else {
            return inMemoryCache
        }
        do {
            let mySegmentsFile = try Json.encodeFrom(json: jsonContent, to: MySegmentsFile.self)
            inMemoryCache = InMemoryMySegmentsCache(segments: Set(mySegmentsFile.segments))
        } catch {
            Logger.e("Error while loading Splits from disk")
        }
        return inMemoryCache
    }

    private func saveSegments() {
        let splitsFile = MySegmentsFile(matchingKey: matchingKey, segments: getSegments())
        do {
            let jsonSplits = try Json.encodeToJson(splitsFile)
            fileStorage.write(fileName: fileNameForCurrentMatchingKey(), content: jsonSplits)
        } catch {
            Logger.e("Could not save splits on disk")
        }
    }
}
