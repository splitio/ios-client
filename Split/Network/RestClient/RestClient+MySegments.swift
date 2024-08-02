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
                       completion: @escaping (DataResult<SegmentChange>) -> Void)
}

extension DefaultRestClient: RestClientMySegments {
    func getMySegments(user: String,
                       headers: [String: String]? = nil,
                       completion: @escaping (DataResult<SegmentChange>) -> Void) {
        let completionHandler: (DataResult<[String: [Segment]]>) -> Void = { result in
            do {
                let data = try result.unwrap()
                var segments = [Segment]()
                if let data = data {
                    segments = data["mySegments"] ?? []
                }
                completion(DataResult.success(value: SegmentChange(segments: segments,
                                                                   changeNumber: -1))
                )
            } catch {
                completion(DataResult.failure(error: error as NSError))
            }
        }
        self.execute(endpoint: endpointFactory.mySegmentsEndpoint(userKey: user),
                     headers: headers,
                     completion: completionHandler)
    }
}
