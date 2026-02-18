// Bundle+Name.swift
// Created by Javier Avrudsky on 19/10/2021.
// Copyright © 2021 Split. All rights reserved.

import Foundation

extension Foundation.Bundle {
    static var splitBundleName: String {
        #if COCOAPODS
        "SplitBundle"
        #else
        "Split_Split"
        #endif
    }
}
