//
//  SseConnectionManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol SseConnectionManager {
    func start()
    func stop()
    func pause()
    func resume()
    func availabilityHandler(streamingEnabled: Bool)
}

class DefaultSseConnectionManager {

    private static let kSseKeepAliveTimeInSeconds = 70
    private static let kReconnectTimeBeforeTokenExpInASeconds = 600
    private static let kDisconnectOnBgTimeInSeconds = 60
    private static let kTokenExpiredErrorCode = 40142

//    private let sseClient: SseClient
//    private let authBackoffCounter: ReconnectBackoffCounter
//    private let sseBackoffCounter: ReconnectBackoffCounter

}
