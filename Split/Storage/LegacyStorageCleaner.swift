//
//  StorageMigrator.swift
//  Split
//
//  Created by Javier Avrudsky on 11/02/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

enum LegacyStorageCleaner {
    static private let kImpressionsFileName: String = "SPLITIO.impressions"
    static private let kEventsFileName: String = "SPLITIO.events_track"
    static private let kSplitsFileName: String = "SPLITIO.splits"
    static private let kMySegmentsFileNamePrefix = "SPLITIO.mySegments"

    static func deleteFiles(fileStorage: FileStorage, userKey: String) {
        DispatchQueue.general.async {
            let mySegmentsFileName = "\(kMySegmentsFileNamePrefix)_\(userKey)"
            fileStorage.delete(fileName: kImpressionsFileName)
            fileStorage.delete(fileName: kEventsFileName)
            fileStorage.delete(fileName: kSplitsFileName)
            fileStorage.delete(fileName: mySegmentsFileName)
        }
    }
}
