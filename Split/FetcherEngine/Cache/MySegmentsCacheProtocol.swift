//
//  SegmentsCacheProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation
@available(*, deprecated, message: "To be removed in integration PR")
protocol MySegmentsCacheProtocol {
    func setSegments(_ segments: [String])
    func removeSegments()
    func getSegments() -> [String]
    func isInSegments(name: String) -> Bool
    func clear()
}
