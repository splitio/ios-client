//
//  DependencyMatcher.swift
//  Split
//
//  Created by Natalia  Stele on 11/14/17.
//


import Foundation



public class DependencyMatcher: BaseMatcher, MatcherProtocol  {
    
    
    var dependencyData: DependencyMatcherData?
    //--------------------------------------------------------------------------------------------------
    public init(splitClient: SplitClient? = nil, negate: Bool? = nil, atributte: String? = nil , type: MatcherType? = nil, dependencyData: DependencyMatcherData?) {
        
        super.init(splitClient: splitClient, negate: negate, atributte: atributte, type: type)
        self.dependencyData = dependencyData
    }
 
    //--------------------------------------------------------------------------------------------------
    public func evaluate(matchValue: Any?, bucketingKey: String?, atributtes: [String:Any]?) -> Bool {
        
        var composeKey: Key?
        
        if let key = matchValue as? String, let splitName = dependencyData?.split {
            
            if let bucketKey = bucketingKey {
                
                composeKey = Key(matchingKey: key, bucketingKey: bucketKey)
                
            } else {
                
                composeKey = Key(matchingKey: key, bucketingKey: key)

            }
            
            var treatment: String?
            
            if let keys = composeKey  {
                
                do {
                    
                    treatment = try splitClient?.getTreatment(key: keys, split:splitName , atributtes: atributtes)
                
                }
                catch {
                    
                    treatment = SplitConstants.CONTROL
                }
                
            }
            
            if let treatments = dependencyData?.treatments {
                
                return treatments.contains(treatment!)
                
            } else {
                
                return false
                
            }
            
        }
        
        return false
    }
    
}
