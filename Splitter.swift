//
//  Splitter.swift
//  Split
//
//  Created by Natalia  Stele on 11/7/17.
//

import Foundation

public protocol SplitterProtocol {
    
    func getTreatment(key: Key, seed: Int, atributtes:[String:Any]?, partions: [Partition]?, algo: Int) -> String
    
    func getBucket(seed: Int,key: String ,algo: Int) -> Int
    
}

public class Splitter: SplitterProtocol {
    
    public static let shared: Splitter = {
        
        let instance = Splitter();
        return instance;
    }()
 
    public func getTreatment(key: Key, seed: Int, atributtes: [String : Any]?, partions: [Partition]?, algo: Int) -> String {
        
        var accumulatedSize: Int = 0
        
        print("Splitter evaluating partitions ... \n")
        
        let bucket: Int = getBucket(seed: seed, key: key.bucketingKey! ,algo: algo)
        debugPrint("BUCKET: \(bucket)")
        
        if let splitPartitions = partions {
            
            for partition in splitPartitions {
                
                print("PARTITION SIZE \(String(describing: partition.size)) PARTITION TREATMENT: \(String(describing: partition.treatment)) \n")
                
                accumulatedSize = partition.size!
                
                if bucket <= accumulatedSize {
                    
                    print("TREATMENT RETURNED:\(partition.treatment!)")
                    return partition.treatment!
                    
                }
                
            }
            
        }
        
        return SplitClient.CONTROL // should return control or nil here?
    }
    
    public func getBucket(seed: Int, key: String ,algo: Int) -> Int {
        
        let hashCode = Murmur3Hash.hashString(key, UInt32(seed))
        
        let bucket = (hashCode  % 100) + 1
        
        return Int(bucket)
        
    }
    
}
