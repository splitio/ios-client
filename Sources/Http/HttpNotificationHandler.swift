//
//  HttpNotificationHandler.swift
//  Http
//
//  Protocol for posting HTTP-layer notifications (e.g. pinning results).
//

import Foundation

/// A protocol for posting HTTP-layer notifications.
///
/// Used by ``DefaultHttpRequestManager`` to report certificate pinning
/// events back to the host application.
public protocol HttpNotificationHandler: Sendable {
    func notifyPinningFailure(host: String)
    func notifyPinningStatus(_ status: CertificatePinningCompleteStatus)
}
