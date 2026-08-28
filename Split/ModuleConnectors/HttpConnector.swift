//  Http module imports for the Split module
//  Copyright © 2026 Split. All rights reserved.

#if SWIFT_PACKAGE

import Http

// Re-export only CertificatePinningStatus for SDK consumers, to be used by the handlers
@_exported import enum Http.CertificatePinningStatus

// MARK: - Internal use
typealias HttpClient = Http.HttpClient
typealias HttpResponse = Http.HttpResponse
typealias HttpSessionConfig = Http.HttpSessionConfig
typealias HttpAuthenticator = Http.HttpAuthenticator
typealias HttpNotificationHandler = Http.HttpNotificationHandler
typealias HttpHeaders = Http.HttpHeaders
typealias HttpParameters = Http.HttpParameters
typealias HttpParameter = Http.HttpParameter
typealias HttpError = Http.HttpError
typealias HttpCode = Http.HttpCode
typealias HttpStreamRequest = Http.HttpStreamRequest
typealias Endpoint = Http.Endpoint
typealias CredentialPin = Http.CredentialPin
typealias KeyHashAlgo = Http.KeyHashAlgo
typealias CertificatePinningCompleteStatus = Http.CertificatePinningCompleteStatus
typealias DefaultHttpClient = Http.DefaultHttpClient
typealias DefaultTlsPinChecker = Http.DefaultTlsPinChecker
typealias TlsPinChecker = Http.TlsPinChecker
typealias TlsCertificateParser = Http.TlsCertificateParser
typealias AlgoHelper = Http.AlgoHelper
typealias InternalHttpErrorCode = Http.InternalHttpErrorCode
#endif
