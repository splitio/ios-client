// HttpTestConnector.swift
// Created by Split Team.
// Copyright © 2025 Split. All rights reserved.

#if SWIFT_PACKAGE || SPLIT_MODULAR
import SplitHttp

// MARK: - Http types for testing

typealias HttpRequest = SplitHttp.HttpRequest
typealias HttpDataRequest = SplitHttp.HttpDataRequest
typealias HttpStreamRequest = SplitHttp.HttpStreamRequest
typealias HttpSession = SplitHttp.HttpSession
typealias HttpTask = SplitHttp.HttpTask
typealias HttpRequestList = SplitHttp.HttpRequestList
typealias HttpRequestManager = SplitHttp.HttpRequestManager
typealias HttpMethod = SplitHttp.HttpMethod
typealias HttpHeaders = SplitHttp.HttpHeaders
typealias HttpParameters = SplitHttp.HttpParameters
typealias HttpError = SplitHttp.HttpError
typealias HttpResponse = SplitHttp.HttpResponse
typealias HttpClient = SplitHttp.HttpClient
typealias DefaultHttpClient = SplitHttp.DefaultHttpClient
typealias DefaultHttpDataRequest = SplitHttp.DefaultHttpDataRequest
typealias DefaultHttpStreamRequest = SplitHttp.DefaultHttpStreamRequest
typealias DefaultHttpRequestManager = SplitHttp.DefaultHttpRequestManager
typealias CredentialValidationResult = SplitHttp.CredentialValidationResult
typealias CredentialPin = SplitHttp.CredentialPin
typealias KeyHashAlgo = SplitHttp.KeyHashAlgo
typealias TlsPinChecker = SplitHttp.TlsPinChecker
typealias CertificatePinningStatus = SplitHttp.CertificatePinningStatus
typealias CertificatePinningCompleteStatus = SplitHttp.CertificatePinningCompleteStatus
typealias HttpSessionConfig = SplitHttp.HttpSessionConfig
typealias HttpNotificationHandler = SplitHttp.HttpNotificationHandler
typealias Endpoint = SplitHttp.Endpoint
typealias HostDomainFilter = SplitHttp.HostDomainFilter
typealias CertKeyType = SplitHttp.CertKeyType
typealias CertSpki = SplitHttp.CertSpki
typealias TlsCertificateParser = SplitHttp.TlsCertificateParser
typealias AlgoHelper = SplitHttp.AlgoHelper
#endif
