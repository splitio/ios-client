//
//  DispatchQueue+Test.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

extension DispatchQueue {
    static let test = { DispatchQueue(label: "split-test-queue", attributes: .concurrent) }()

    static let reqManager = { DispatchQueue(label: "split-reqman-queue", attributes: .concurrent) }()
}
