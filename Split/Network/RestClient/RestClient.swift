//
//  Api.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol RestClientProtocol {
    func isServerAvailable(_ url: URL) -> Bool
    func isServerAvailable(path url: String) -> Bool
    func isEventsServerAvailable() -> Bool
    func isSdkServerAvailable() -> Bool
}

/*@objc public final */
class RestClient: NSObject {
    // MARK: - Private Properties
    private let manager: RestClientManagerProtocol

    // MARK: - Designated Initializer
    init(manager: RestClientManagerProtocol = RestClientConfiguration.manager) {
        self.manager = manager
    }

    // MARK: - Private Functions
    private func start<T: Any>(target: Target, completion: @escaping (DataResult<T>) -> Void) where T: Decodable {
        _ = manager.sendRequest(target: target).getResponse(errorSanitizer: target.errorSanitizer) { response in
            switch response.result {
            case .success(let json):
                if json.isNull() {
                    completion(DataResult { return nil })
                    return
                }

                do {
                    let parsedObject = try json.decode(T.self)
                    completion(DataResult { return parsedObject })
                } catch {
                    completion(DataResult { throw error })
                }
            case .failure(let error):
                completion(DataResult { throw error })
            }
        }
    }

    // MARK: - Internal Functions
    internal func execute<T>(target: Target, completion: @escaping (DataResult<T>) -> Void) where T: Decodable {
        self.start(target: target, completion: completion)
    }
}

extension RestClient: RestClientProtocol {
    func isServerAvailable(_ url: URL) -> Bool {
        return self.isServerAvailable(path: url.absoluteString)
    }

    func isServerAvailable(path url: String) -> Bool {
        if let reachabilityManager = NetworkReachabilityManager(host: url) {
            return reachabilityManager.isReachable
        }
        return false
    }

    func isEventsServerAvailable() -> Bool {
        return self.isServerAvailable(EnvironmentTargetManager.shared.eventsBaseURL)
    }

    func isSdkServerAvailable() -> Bool {
        return self.isServerAvailable(EnvironmentTargetManager.shared.sdkBaseUrl)
    }
}
