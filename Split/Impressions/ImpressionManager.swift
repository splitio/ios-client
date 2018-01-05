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
        headers["SplitSDKVersion"] = "go-0.0.1"
        headers["SplitSDKMachineIP"] = "ip-123-123-343-122"
        headers["Authorization"] = "Bearer k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq"


        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        
       // let data = try? JSONSerialization.data(withJSONObject: impressionStorage, options: JSONSerialization.WritingOptions.prettyPrinted)
       // let stringL = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        
        
        let json: JSON = JSON(impressionStorage)
        print(json)
        let jsonString = json.rawValue
        
        print(jsonString)
       // request.httpBody = impressionStorage as? Data

        Alamofire.request(request).validate(statusCode: 200..<300).response { response in
                
                if response.error != nil {
                    
                    print("[IMPRESSION] error : \(String(describing: response.error))")
                }
                
                print("[IMPRESSION FIRED]")
                
        }
        
    }
    
}
