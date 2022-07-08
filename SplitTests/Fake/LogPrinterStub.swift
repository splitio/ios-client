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

    var logs = [String]()

    func print(_ items: Any...) {
        logs.append(items.map { "\($0)" }.joined(separator: ","))
    }
}
