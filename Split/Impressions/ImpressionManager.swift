//
//  ImpressionManager.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation
import Alamofire
import SwiftyJSON

public class ImpressionManager {
    
    private let interval: Int
    private var featurePollTimer: DispatchSourceTimer?
    public weak var dispatchGroup: DispatchGroup?
    public var impressionStorage: [ImpressionDTO] = []

    
    public static let shared: ImpressionManager = {
        
        let instance = ImpressionManager()
        return instance;
    }()
    
    public init(interval: Int = 30, dispatchGroup: DispatchGroup? = nil) {
        self.interval = interval
        self.dispatchGroup = dispatchGroup
    }
    
    public func sendImpressions() {
        
        let url: URL = URL(string: "https://events-aws-staging.split.io/api/testImpressions/bulk")!
        var headers: HTTPHeaders = [:]
        headers["splitsdkversion"] = "go-23.1.1"
        headers["splitsdkmachineip"] = "123.123.123.123"
        headers["splitsdkmachinename"] = "ip-127-0-0-1"
        headers["authorization"] = "Bearer k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq"
        headers["content-type"] = "application/json"


        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers
        

        
        let hit = ImpressionsHit()
        
        hit.keyImpressions = impressionStorage
        hit.testName = "all_feature"
        
        var hits: [ImpressionsHit] = []
        
        hits.append(hit)
        
        let encodedData = try? JSONEncoder().encode(hits)
        
        
        let json = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)
        if let json = json {
            print(json)
        }
    
        
     
        request.httpBody = encodedData
        let params = request.allHTTPHeaderFields
        print(params)

        Alamofire.request(request).validate(statusCode: 200..<300).response { response in
                
                if response.error != nil {
                    
                    print("[IMPRESSION] error : \(String(describing: response.error))")
                }
                
                print("[IMPRESSION FIRED]")
                
        }
        
    }
    
}
