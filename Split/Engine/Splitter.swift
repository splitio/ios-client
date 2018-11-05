//
//  Splitter.swift
//  Split
//
//  Created by Natalia  Stele on 11/7/17.
//

import Foundation

public protocol SplitterProtocol {
    
    func getTreatment(key: Key, seed: Int, attributes:[String:Any]?, partions: [Partition]?, algo: Int) -> String
    
    func getBucket(seed: Int,key: String ,algo: Int) -> Int
    
}

public class Splitter: SplitterProtocol {
    
    public static let ALGO_LEGACY: Int = 1
    public static let ALGO_MURMUR: Int = 2
    //------------------------------------------------------------------------------------------------------------------
    
    public static let shared: Splitter = {
        
        let instance = Splitter();
        return instance;
    }()
    //------------------------------------------------------------------------------------------------------------------
    public func getTreatment(key: Key, seed: Int, attributes: [String : Any]?, partions: [Partition]?, algo: Int) -> String {
        
        var accumulatedSize: Int = 0
        
        Logger.d("Splitter evaluating partitions ... \n")
        
        let bucket: Int = getBucket(seed: seed, key: key.bucketingKey! ,algo: algo)
        Logger.d("BUCKET: \(bucket)")
        
        if let splitPartitions = partions {
            
            for partition in splitPartitions {
                
                Logger.d("PARTITION SIZE \(String(describing: partition.size)) PARTITION TREATMENT: \(String(describing: partition.treatment)) \n")
                
                accumulatedSize = accumulatedSize + partition.size!
                
                if bucket <= accumulatedSize {
                    
                    Logger.d("TREATMENT RETURNED:\(partition.treatment!)")
                    return partition.treatment!
                    
                }
                
            }
            
        }
        
        return SplitConstants.CONTROL
    }
    //------------------------------------------------------------------------------------------------------------------
    public func getBucket(seed: Int, key: String ,algo: Int) -> Int {
        
        let hashCode: UInt32 = self.hashCode(seed: seed, key: key, algo: algo)
        
        let bucket = (hashCode  % 100) + 1
        
        return Int(bucket)
        
    }
    //------------------------------------------------------------------------------------------------------------------
    private func hashCode(seed: Int, key: String ,algo: Int) -> UInt32 {
        
        switch algo {
            
        case Splitter.ALGO_LEGACY:
            
            return LegacyHash.getHash(key, UInt32(seed))
            
        case Splitter.ALGO_MURMUR:
            
            
            return Murmur3Hash.hashString(key, UInt32(truncatingIfNeeded: seed))
            
            
            
        default:
            
            return LegacyHash.getHash(key, UInt32(seed))
        }
        
    }
    //------------------------------------------------------------------------------------------------------------------
}
