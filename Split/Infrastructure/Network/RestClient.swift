//
//  Api.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

@objc public final class RestClient: NSObject {
    // MARK: - Private Properties
    private let manager: RestClientManagerProtocol
    
    // MARK: - Designated Initializer
    init(manager: RestClientManagerProtocol = RestClientConfiguration.manager) {
        self.manager = manager
    }
    
    // MARK: - Private Functions
    private func start<T: Any>(target: Target, completion: @escaping (DataResult<T>) -> Void, processResponse: @escaping (JSON) -> Any?) {
        let _ = manager.sendRequest(target: target).getResponse(errorSanitizer: target.errorSanitizer) { response in
            switch response.result {
            case .success(let json):
                let parsedObject = processResponse(json) as! T
                completion( DataResult{ return parsedObject } )
            case .failure(let error):
                completion( DataResult{ throw error })
            }
        }
    }
    
    // MARK: - Internal Functions
    internal func execute(target: Target, completion: @escaping (DataResult<Void>) -> Void, processResponse: @escaping (JSON) -> Void) {
        self.start(target: target, completion: completion, processResponse: processResponse)
    }
    
    internal func execute<T: AnyObject>(target: Target, completion: @escaping (DataResult<T>) -> Void, processResponse: @escaping (JSON) -> T?) {
        self.start(target: target, completion: completion, processResponse: processResponse)
    }
    
    internal func execute<T: AnyObject>(target: Target, completion: @escaping (DataResult<[T]>) -> Void, processResponse: @escaping (JSON) -> [T]?) {
        self.start(target: target, completion: completion, processResponse: processResponse)
    }
}
