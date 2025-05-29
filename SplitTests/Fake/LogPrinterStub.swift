//
//  LogPrinterStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 08-Jul-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class LogPrinterStub: LogPrinter {
    private(set) var logs = [String]()

    private let queue = DispatchQueue(
        label: "Split.LogPrinterStub",
        target: .global())

    func stdout(_ items: Any...) {
        queue.sync {
            self.logs.append(items.map { "\($0)" }.joined(separator: ","))
        }
    }

    func clear() {
        queue.sync {
            self.logs.removeAll()
        }
    }
}
