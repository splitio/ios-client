//
//  SegmentsCacheProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

protocol MySegmentsCacheProtocol {
    func setSegments(_ segments: [String])
    func removeSegments()
    func getSegments() -> [String]
    func isInSegments(name: String) -> Bool
    func clear()
}
