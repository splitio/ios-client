//
//  ImpressionsHit.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/19/18.
//
// ToDo: Replace with generic implemention for track events and impressions. Temporal implementation.
import Foundation

class ImpressionsHit: Codable {
    var identifier: String
    var impressions: [ImpressionsTest]
    var attempts: Int = 0

    init(identifier: String, impressions: [ImpressionsTest]) {
        self.identifier = identifier
        self.impressions = impressions
    }

    func addAttempt() {
        attempts += 1
    }

}
