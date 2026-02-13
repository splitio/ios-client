//
//  HttpTestTypealiases.swift
//  SplitTests
//
//  Centralizes Http module imports for tests
//

#if !COCOAPODS
import Http

// MARK: - Http types for testing

typealias HttpRequest = Http.HttpRequest
typealias HttpDataRequest = Http.HttpDataRequest
typealias HttpStreamRequest = Http.HttpStreamRequest
typealias HttpSession = Http.HttpSession
typealias HttpTask = Http.HttpTask
typealias HttpRequestList = Http.HttpRequestList
typealias HttpRequestManager = Http.HttpRequestManager
typealias HttpMethod = Http.HttpMethod
typealias HttpHeaders = Http.HttpHeaders
typealias HttpParameters = Http.HttpParameters
typealias HttpError = Http.HttpError
typealias HttpResponse = Http.HttpResponse
typealias HttpClient = Http.HttpClient
typealias DefaultHttpClient = Http.DefaultHttpClient
typealias DefaultHttpDataRequest = Http.DefaultHttpDataRequest
typealias DefaultHttpStreamRequest = Http.DefaultHttpStreamRequest
typealias DefaultHttpRequestManager = Http.DefaultHttpRequestManager
typealias CredentialValidationResult = Http.CredentialValidationResult
typealias CredentialPin = Http.CredentialPin
typealias KeyHashAlgo = Http.KeyHashAlgo
typealias TlsPinChecker = Http.TlsPinChecker
typealias CertificatePinningStatus = Http.CertificatePinningStatus
typealias CertificatePinningCompleteStatus = Http.CertificatePinningCompleteStatus
typealias HttpSessionConfig = Http.HttpSessionConfig
typealias HttpNotificationHandler = Http.HttpNotificationHandler
typealias Endpoint = Http.Endpoint
typealias HostDomainFilter = Http.HostDomainFilter
typealias CertKeyType = Http.CertKeyType
typealias CertSpki = Http.CertSpki
typealias TlsCertificateParser = Http.TlsCertificateParser
typealias AlgoHelper = Http.AlgoHelper
#endif
