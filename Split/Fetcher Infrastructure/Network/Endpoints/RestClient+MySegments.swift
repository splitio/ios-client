//
//  RestClient+MySegments.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

extension RestClient {
    
    func getMySegments(user: String, completion: @escaping (DataResult<[String]>) -> Void) {
        
        let completionHandler: (DataResult<[String:[Segment]]>) -> Void = { result in
            do {
                let data = try result.unwrap()
                var segmentsNames = [String]()
                if let data = data, let segments = data["mySegments"]  {
                    segmentsNames = segments.map { segment in  return segment.name }
                }
                completion(DataResult.Success(value: segmentsNames))
            } catch {
                completion(DataResult.Failure(error: error as NSError))
            }
        }
        self.execute(target: EnvironmentTargetManager.getMySegments(user: user), completion: completionHandler)
    }
    
}
