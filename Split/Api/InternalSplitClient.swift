//
//  InternalSplitClient.swift
//  Split
//
//  Created by Javier L. Avrudsky on 27/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// Temporal workaround to allow adding some
//  missing evaluator and engine missing tests
/// until we can do a refactor in many classes
///
protocol InternalSplitClient: SplitClient {
    var splitsStorage: SplitsStorage? { get }
    var mySegmentsStorage: MySegmentsStorage? { get }
}

protocol TelemetrySplitClient: SplitClient {
    var initStopwatch: Stopwatch? { get set }
}
