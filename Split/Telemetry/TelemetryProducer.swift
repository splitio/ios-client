//
//  TelemetryProducer.swift
//  Split
//
//  Created by Javier Avrudsky on 01-Dec-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

// Dummy components to replace old telemetry parameters instead of
// remove and create new ones in future tickets
protocol TelemetryInitProducer {
}

protocol TelemetryEvaluationProducer {
}

protocol TelemetryRuntimeProducer {
}

class TelemetryProducer: TelemetryInitProducer,
                         TelemetryEvaluationProducer,
                         TelemetryRuntimeProducer {
}
