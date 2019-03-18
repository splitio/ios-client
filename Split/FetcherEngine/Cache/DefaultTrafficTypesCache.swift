//
//  DefaultTrafficTypesCache.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03/18/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/// ** Default Traffic Types Cache **
/// Handles Traffic Types Cache by loading them
/// from disk into memory when the class is instantiated.
/// In memory traffic types are updated each time new information is retrieved
/// from the server and it is saved to disk when application goes to background.

class DefaultTrafficTypesCache: TrafficTypesCache {
    
    private typealias TrafficTypeFile = [String]
    private let kTrafficTypesFileName  = "SPLITIO.trafficTypes"
    private var fileStorage: FileStorageProtocol
    private var inMemoryCache: TrafficTypesCache!
    
    init(fileStorage: FileStorageProtocol) {
        self.fileStorage = fileStorage
        self.inMemoryCache = initialInMemoryCache()
        NotificationHelper.instance.addObserver(for: AppNotification.didEnterBackground) {
            DispatchQueue.global().async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.saveTrafficTypes()
            }
        }
    }
    
    func set(trafficTypes: [String]) {
        inMemoryCache.set(trafficTypes: trafficTypes)
    }
    
    func removeAll() {
        inMemoryCache.removeAll()
    }
    
    func getAll() -> [String] {
        return inMemoryCache.getAll()
    }
    
    func isInTrafficTypes(name: String) -> Bool {
        return inMemoryCache.isInTrafficTypes(name: name)
    }
}

// MARK: Private
extension DefaultTrafficTypesCache {
    private func fileName() -> String {
        return kTrafficTypesFileName
    }
    
    private func initialInMemoryCache() -> TrafficTypesCache {
        var inMemoryCache = InMemoryTrafficTypesCache(trafficTypes: Set<String>())
        guard let jsonContent = fileStorage.read(fileName: fileName()) else {
            return inMemoryCache
        }
        do {
            let trafficTypeFile = try Json.encodeFrom(json: jsonContent, to: TrafficTypeFile.self)
            inMemoryCache = InMemoryTrafficTypesCache(trafficTypes: Set(trafficTypeFile))
        } catch {
            Logger.e("Error while loading Splits from disk")
        }
        return inMemoryCache
    }
    
    private func saveTrafficTypes() {
        let trafficTypesFile = getAll()
        do {
            let json = try Json.encodeToJson(trafficTypesFile)
            fileStorage.write(fileName: fileName(), content: json)
        } catch {
            Logger.e("Could not save splits on disk")
        }
    }
}
