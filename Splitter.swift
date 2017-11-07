//
//  Splitter.swift
//  Split
//
//  Created by Natalia  Stele on 11/7/17.
//

import Foundation

public protocol SplitterProtocol {
    
    func getTreatment(key: Key, seed: Int, atributtes:[String:Any]?, partions: [Partition]?, algo: Int) -> String
    
    func getBucket(seed: Int, algo: Int) -> Int
    
}

public class Splitter: SplitterProtocol {
    
 
    public func getTreatment(key: Key, seed: Int, atributtes: [String : Any]?, partions: [Partition]?, algo: Int) -> String {
        
        var accumulatedSize: Int = 0
        
        debugPrint("Splitter evaluating partitions ...")
        
        let bucket: Int = getBucket(seed: seed, algo: algo)
        debugPrint("BUCKET: \(bucket)")
        
        if let splitPartitions = partions {
            
            for partition in splitPartitions {
                
                debugPrint("PARTITION SIZE \(String(describing: partition.size)) PARTITION TREATMENT: \(String(describing: partition.treatment))\n")
                
                accumulatedSize = partition.size!
                
                if bucket <= accumulatedSize {
                    
                    return partition.treatment!
                    
                }
                
            }
            
        }
        
        return SplitClient.CONTROL // should return control or nil here?
    }
    
    public func getBucket(seed: Int, algo: Int) -> Int {
        
        return 100
        
    }
    
}
