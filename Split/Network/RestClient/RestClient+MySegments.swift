//
//  RestClient+MySegments.swift
//  Split
//
//  Created by Javier Avrudsky on 31/07/24.
//
//

import Foundation
protocol RestClientMySegments: RestClient {
    func getMySegments(
        user: String,
        till: Int64?,
        headers: [String: String]?,
        completion: @escaping (DataResult<AllSegmentsChange>) -> Void)
}

extension DefaultRestClient: RestClientMySegments {
    func getMySegments(
        user: String,
        till: Int64?,
        headers: [String: String]? = nil,
        completion: @escaping (DataResult<AllSegmentsChange>) -> Void) {
        let completionHandler: ((DataResult<AllSegmentsChange>) -> Void) = { result in
            do {
                let data = try result.unwrap()
                if let segmentsChange = data {
                    completion(DataResult.success(value: segmentsChange))
                } else {
                    completion(
                        DataResult.failure(error: HttpError.unknown(
                            code: -1,
                            message: "No data received") as NSError))
                }

            } catch {
                completion(DataResult.failure(error: error as NSError))
            }
        }
        execute(
            endpoint: endpointFactory.mySegmentsEndpoint(userKey: user),
            parameters: buildParams(till),
            headers: headers,
            completion: completionHandler)
    }

    private func buildParams(_ till: Int64?) -> HttpParameters? {
        guard let till = till else {
            return nil
        }
        return HttpParameters([HttpParameter(key: "till", value: till)])
    }
}
