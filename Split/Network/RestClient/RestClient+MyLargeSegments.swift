//
//  RestClient+MyLargeSegments.swift
//  Split
//
//  Created by Javier Avrudsky on 31/07/24.
//
//

import Foundation
protocol RestClientMyLargeSegments {
    func getMyLargeSegments(user: String,
                            headers: [String: String]?,
                            completion: @escaping (DataResult<SegmentChange>) -> Void)
}

extension DefaultRestClient: RestClientMyLargeSegments {
    func getMyLargeSegments(user: String,
                            headers: [String: String]? = nil,
                            completion: @escaping (DataResult<SegmentChange>) -> Void) {

        let completionHandler: ((DataResult<SegmentChange>) -> Void) = { result in
            do {
                let data = try result.unwrap()
                if let segmentsChange = data {
                    completion(DataResult.success(value: segmentsChange))
                } else {
                    completion(
                        DataResult.failure(error: HttpError.unknown(code: -1,
                                                                    message: "No data received") as NSError))
                }

            } catch {
                completion(DataResult.failure(error: error as NSError))
            }
        }
        self.execute(endpoint: endpointFactory.myLargeSegmentsEndpoint(userKey: user),
                     headers: headers,
                     completion: completionHandler)
    }
}
