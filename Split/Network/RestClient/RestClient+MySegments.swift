//
//  RestClient+MySegments.swift
//  Split
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

protocol RestClientMySegments: RestClient {
    func getMySegments(user: String,
                       headers: [String: String]?,
                       completion: @escaping (DataResult<[String]>) -> Void)
}

extension DefaultRestClient: RestClientMySegments {
    func getMySegments(user: String,
                       headers: [String: String]? = nil,
                       completion: @escaping (DataResult<[String]>) -> Void) {
        let completionHandler: (DataResult<[String: [Segment]]>) -> Void = { result in
            do {
                let data = try result.unwrap()
                var segmentsNames = [String]()
                if let data = data, let segments = data["mySegments"] {
                    segmentsNames = segments.map { segment in  return segment.name }
                }
                completion(DataResult.success(value: segmentsNames))
            } catch {
                completion(DataResult.failure(error: error as NSError))
            }
        }
        self.execute(endpoint: endpointFactory.mySegmentsEndpoint(userKey: user),
                     headers: headers,
                     completion: completionHandler)
    }
}
