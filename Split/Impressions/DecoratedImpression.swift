//
//  DecoratedImpression.swift
//  Split
//
//  Copyright © 2024 Split. All rights reserved.
//

struct DecoratedImpression {
    let impression: KeyImpression
    let impressionsDisabled: Bool

    init(impression: KeyImpression, impressionsDisabled: Bool) {
        self.impression = impression
        self.impressionsDisabled = impressionsDisabled
    }
}
