//
//  RestClient+MySegments.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

protocol RestClientMySegments: RestClientProtocol {
    func getMySegments(user: String, completion: @escaping (DataResult<[String]>) -> Void)
}

extension RestClient: RestClientMySegments {

    func getMySegments(user: String, completion: @escaping (DataResult<[String]>) -> Void) {
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
        self.execute(target: EnvironmentTargetManager.getMySegments(user: user), completion: completionHandler)
    }
}
