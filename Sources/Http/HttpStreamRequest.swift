//
//  HttpStreamRequest.swift
//  Http
//

import Foundation

public protocol HttpStreamRequest: HttpRequest, HttpDataReceivingRequest {
    typealias ResponseHandler = @Sendable (HttpResponse) -> Void
    typealias IncomingDataHandler = @Sendable (Data) -> Void
    typealias CloseHandler = @Sendable () -> Void
    typealias ErrorHandler = @Sendable (HttpError) -> Void

    func getResponse(responseHandler: @escaping ResponseHandler,
                     incomingDataHandler: @escaping IncomingDataHandler,
                     closeHandler: @escaping CloseHandler,
                     errorHandler: @escaping ErrorHandler) -> Self
    func close()
}

public class DefaultHttpStreamRequest: BaseHttpRequest, HttpStreamRequest, @unchecked Sendable {
    public var responseHandler: DefaultHttpStreamRequest.ResponseHandler?
    public var incomingDataHandler: DefaultHttpStreamRequest.IncomingDataHandler?
    public var closeHandler: DefaultHttpStreamRequest.CloseHandler?

    public init(session: HttpSession, url: URL, parameters: HttpParameters?, headers: HttpHeaders?) throws {
        try super.init(session: session, url: url, method: .get, parameters: parameters, headers: headers)
    }

    public override func notifyIncomingData(_ data: Data) {
        incomingDataHandler?(data)
    }

    @discardableResult
    public func response(
        queue: DispatchQueue? = nil,
        responseHandler: @escaping @Sendable DefaultHttpStreamRequest.ResponseHandler,
        incomingDataHandler: @escaping @Sendable DefaultHttpStreamRequest.IncomingDataHandler,
        closeHandler: @escaping @Sendable DefaultHttpStreamRequest.CloseHandler,
        errorHandler: @escaping @Sendable DefaultHttpStreamRequest.ErrorHandler
    ) -> Self {
        self.responseHandler = responseHandler
        self.incomingDataHandler = incomingDataHandler
        self.closeHandler = closeHandler
        self.errorHandler = errorHandler
        return self
    }

    public func getResponse(
        responseHandler: @escaping @Sendable DefaultHttpStreamRequest.ResponseHandler,
        incomingDataHandler: @escaping @Sendable DefaultHttpStreamRequest.IncomingDataHandler,
        closeHandler: @escaping @Sendable DefaultHttpStreamRequest.CloseHandler,
        errorHandler: @escaping @Sendable DefaultHttpStreamRequest.ErrorHandler
    ) -> Self {
        response(
            queue: DispatchQueue(label: HttpQueue.default),
            responseHandler: responseHandler,
            incomingDataHandler: incomingDataHandler,
            closeHandler: closeHandler,
            errorHandler: errorHandler
        )
    }

    public func close() {
        task?.cancel()
    }

    public override func setResponse(code: Int) {
        responseHandler?(HttpResponse(code: code))
    }

    public override func complete(error: HttpError?) {
        if let error = error, let errorHandler = self.errorHandler {
            errorHandler(error)
        } else {
            closeHandler?()
        }
    }
}

extension DefaultHttpStreamRequest: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        urlRequest?.description ?? "No description available: Null"
    }

    public var debugDescription: String {
        urlRequest?.debugDescription ?? "No description available: Null"
    }
}
