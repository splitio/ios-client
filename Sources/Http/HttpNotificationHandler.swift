//  HttpNotificationHandler
//  Copyright © 2024 Split. All rights reserved.

import Foundation

/// Used by ``DefaultHttpRequestManager`` to report certificate pinning events back to the host application.
public protocol HttpNotificationHandler: Sendable {
    func notifyPinningFailure(host: String)
    func notifyPinningStatus(_ status: CertificatePinningCompleteStatus)
}
