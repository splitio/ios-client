//
//  DecoratedImpression.swift
//  Split
//
//  Copyright © 2024 Split. All rights reserved.
//

struct DecoratedImpression {
    let impression: KeyImpression
    let trackImpressions: Bool

    init(impression: KeyImpression, trackImpressions: Bool) {
        self.impression = impression
        self.trackImpressions = trackImpressions
    }
}
