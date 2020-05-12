//
//  Api.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

protocol RestClient {
    func isServerAvailable(_ url: URL) -> Bool
    func isServerAvailable(path url: String) -> Bool
    func isEventsServerAvailable() -> Bool
    func isSdkServerAvailable() -> Bool
}

/*@objc public final */
class DefaultRestClient: NSObject {
    // MARK: - Private Properties
    private let manager: HttpClient

    // MARK: - Designated Initializer
    init(manager: HttpClient = RestClientConfiguration.manager) {
        self.manager = manager
    }

    func execute<T>(target: Target, completion: @escaping (DataResult<T>) -> Void) where T: Decodable {
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
}

extension DefaultRestClient: RestClient {
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
