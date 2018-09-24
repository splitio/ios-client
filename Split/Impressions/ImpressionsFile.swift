//
//  ImpressionsFile.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/19/18.
//
// ToDo: Replace with generic implemention for track events and impressions. Temporal implementation.
import Foundation

class ImpressionsFile: Codable {
    var oldHits: [String: ImpressionsHit]?
    var currentHit: ImpressionsHit?
}
