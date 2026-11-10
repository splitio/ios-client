//  Http module imports for the Split module
//  Copyright © 2026 Split. All rights reserved.

#if SWIFT_PACKAGE || SPLIT_MODULAR

import SplitHttp

// Re-export only CertificatePinningStatus for SDK consumers, to be used by the handlers
@_exported import enum SplitHttp.CertificatePinningStatus

// MARK: - Internal use
typealias HttpClient = SplitHttp.HttpClient
typealias HttpResponse = SplitHttp.HttpResponse
typealias HttpSessionConfig = SplitHttp.HttpSessionConfig
typealias HttpAuthenticator = SplitHttp.HttpAuthenticator
typealias HttpNotificationHandler = SplitHttp.HttpNotificationHandler
typealias HttpHeaders = SplitHttp.HttpHeaders
typealias HttpParameters = SplitHttp.HttpParameters
typealias HttpParameter = SplitHttp.HttpParameter
typealias HttpError = SplitHttp.HttpError
typealias HttpCode = SplitHttp.HttpCode
typealias HttpStreamRequest = SplitHttp.HttpStreamRequest
typealias Endpoint = SplitHttp.Endpoint
typealias CredentialPin = SplitHttp.CredentialPin
typealias KeyHashAlgo = SplitHttp.KeyHashAlgo
typealias CertificatePinningCompleteStatus = SplitHttp.CertificatePinningCompleteStatus
typealias DefaultHttpClient = SplitHttp.DefaultHttpClient
typealias DefaultTlsPinChecker = SplitHttp.DefaultTlsPinChecker
typealias TlsPinChecker = SplitHttp.TlsPinChecker
typealias TlsCertificateParser = SplitHttp.TlsCertificateParser
typealias AlgoHelper = SplitHttp.AlgoHelper
typealias InternalHttpErrorCode = SplitHttp.InternalHttpErrorCode
#endif
