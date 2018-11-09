//
//  MySegmentsCache.swift
//  Split
//
//  Created by Natalia  Stele on 07/12/2017.
//

import Foundation

class MySegmentsCache: MySegmentsCacheProtocol {
    
    private struct MySegmentsFile: Codable {
        var matchingKey: String
        var segments: [String]
    }
    
    private let kMySegmentsFileNamePrefix  = "SEGMENTIO.split.mySegmentsFile"
    private var fileStorage: FileStorageProtocol
    private var inMemoryCache: InMemoryMySegmentsCache!
    private var matchingKey: String

    convenience init(matchingKey: String) {
        self.init(matchingKey: matchingKey, fileStorage: FileStorage())
    }
    
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
    
    func addSegments(_ segments: [String]) {
        inMemoryCache.addSegments(segments)
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
