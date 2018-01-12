//
//  ImpressionManager.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation
import Alamofire
import SwiftyJSON

typealias ImpressionsBulk = [ImpressionsHit]

public class ImpressionManager {
    
    public var interval: Int
    private var featurePollTimer: DispatchSourceTimer?
    public weak var dispatchGroup: DispatchGroup?
    public var impressionStorage: [String:[ImpressionDTO]] = [:]
    private var fileStorage = FileStorage()
    private var impressionsFileStorage: ImpressionsFileStorage?
    
    
    public static let shared: ImpressionManager = {
        
        let instance = ImpressionManager()
        return instance;
    }()
    
    public init(interval: Int = 10, dispatchGroup: DispatchGroup? = nil) {
        self.interval = interval
        self.dispatchGroup = dispatchGroup
        self.impressionsFileStorage = ImpressionsFileStorage(storage: self.fileStorage)
    }
    
    public func sendImpressions() {
        
        let url: URL = URL(string: "https://events-aws-staging.split.io/api/testImpressions/bulk")!
        var headers: HTTPHeaders = [:]
        headers["splitsdkversion"] = "go-23.1.1"
        headers["splitsdkmachineip"] = "123.123.123.123"
        headers["splitsdkmachinename"] = "ip-127-0-0-1"
       // headers["authorization"] = "Bearer k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq"
        headers["content-type"] = "application/json"
        
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers
        
        
        let hits: [ImpressionsHit] = createImpressionsBulk()
        
        let encodedData = try? JSONEncoder().encode(hits)
        let encodedData2 = try? JSONEncoder().encode(hits.first)

        
        let decoder = JSONDecoder()
        if encodedData != nil {
            let jsonDec = try? decoder.decode(ImpressionsBulk.self, from: encodedData!)
            print(jsonDec)
        }
        
        
        let json = NSString(data: encodedData!, encoding: String.Encoding.utf8.rawValue)
        if let json = json {
            print(json)
        }
        
        request.httpBody = encodedData
        
        if json != "[]" {
            
            Alamofire.request(request).validate(statusCode: 200..<300).response {  [weak self] response in
                
                guard let strongSelf = self else {
                    return
                }
                
                if response.error != nil {
                    
                    strongSelf.impressionsFileStorage?.saveImpressions(impressions: json! as String)
                    let imp = strongSelf.impressionsFileStorage?.readImpressions()
                    
                    print("[IMPRESSION] error : \(String(describing: response.error))")
                    
                } else {
                    
                    print("[IMPRESSION FIRED]")
                    strongSelf.cleanImpressions()
                    
                }
                
            }
        }
    }
    
    
    public func appendImpressions(impression: ImpressionDTO, splitName: String) {
        
        
        var impressionsArray = impressionStorage[splitName]
        
        if  impressionsArray != nil {
        
            impressionsArray?.append(impression)
            
            impressionStorage[splitName] = impressionsArray

            
        } else {
            
            impressionsArray = []
            impressionsArray?.append(impression)
            impressionStorage[splitName] = impressionsArray
            
        }
        
        
    }
    
    public func createImpressionsBulk() -> [ImpressionsHit] {
        
        var hits: [ImpressionsHit] = []
        
        for key in impressionStorage.keys {
            
            let array = impressionStorage[key]

            let hit = ImpressionsHit()
            hit.keyImpressions = array
            hit.testName = key
            hits.append(hit)

        }
        
        return hits
    }
    
    
    
    private func startPollingForImpressions() {
        let queue = DispatchQueue(label: "split-polling-queue")
        featurePollTimer = DispatchSource.makeTimerSource(queue: queue)
        featurePollTimer!.schedule(deadline: .now(), repeating: .seconds(self.interval))
        featurePollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.featurePollTimer != nil else {
                strongSelf.stopPollingForSendImpressions()
                return
            }
            strongSelf.pollForSendImpressions()
        }
        featurePollTimer!.resume()
    }
    
    private func stopPollingForSendImpressions() {
        featurePollTimer?.cancel()
        featurePollTimer = nil
    }
    
    private func pollForSendImpressions() {
        dispatchGroup?.enter()
        let queue = DispatchQueue(label: "split-impressions-queue")
        queue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            do {
                
                strongSelf.sendImpressions()
                
                strongSelf.dispatchGroup?.leave()
                
            } catch let error {
                
                //TODO: throw error when impressions fail
                debugPrint("Problem fetching splitChanges: %@", error.localizedDescription)
            }
        }
    }
    
    public func start() {
        startPollingForImpressions()
    }
    
    
    public func stop() {
        stopPollingForSendImpressions()
    }
    
    private func cleanImpressions() {
        
        impressionStorage = [:]
        impressionsFileStorage?.deleteImpressions()

    }
}
