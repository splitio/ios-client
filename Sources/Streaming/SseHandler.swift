//
//  SseHandler.swift
//  Split
//
//  Created by Javier L. Avrudsky on 01/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

public protocol SseHandler: AnyObject {
    func isConnectionConfirmed(message: [String: String]) -> Bool
    func handleIncomingMessage(message: [String: String])
    func reportError(isRetryable: Bool)
}
