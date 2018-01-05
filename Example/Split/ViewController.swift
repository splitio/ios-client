//
//  ViewController.swift
//  Split
//
//  Created by Brian Sztamfater on 09/18/2017.
//  Copyright (c) 2017 Split Software. All rights reserved.
//

import UIKit
import Split

class ViewController: UIViewController {
  
    @IBOutlet weak var splitRefreshRate: UITextField?
    @IBOutlet weak var mySegmentRefreshRate: UITextField?
    @IBOutlet weak var apiKey: UITextField?
    @IBOutlet weak var bucketkey: UITextField?
    @IBOutlet weak var splitName: UITextField?
    @IBOutlet weak var matchingKey: UITextField?
    @IBOutlet weak var evaluteButton: UIButton?
    @IBOutlet weak var treatmentResult: UILabel?
    @IBOutlet weak var param1: UITextField?
    @IBOutlet weak var param2: UITextField?

    @IBAction func evaluate(_ sender: Any) {
        
        var bucketing: String?
        
        let splitRate: String  = "30" //(splitRefreshRate?.text)!
        let sRate = Int(splitRate)
        
        let mySegmentRate: String  = "30" //(mySegmentRefreshRate?.text)!
        let mySegRate = Int(mySegmentRate)
        
        let matchingKeyText: String = (matchingKey?.text)!
        
        
        if let bucketingKeyTexy = bucketkey?.text {
            
            bucketing = bucketingKeyTexy
            
        } else {
            
            bucketing = matchingKey?.text

        }
  
        let config = SplitClientConfig(featuresRefreshRate: sRate, segmentsRefreshRate: mySegRate, blockUntilReady: 50000)
        
        let authorizationKey = "k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq" //apiKey?.text //"k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq"
        
        //let key: Key = Key(matchingKey: matchingKeyText, trafficType: "user", bucketingKey: bucketing)
        let key: Key = Key(matchingKey: "mozi", trafficType: "user", bucketingKey: "mozi")

        
        guard let splitFactory = try? SplitFactory(apiToken: authorizationKey, key: key, config: config) else {
            return
        }
        
        let client = splitFactory.client()
        
        var attributes: [String:Any] = [:]

        if let paramName = param1?.text, let paramValue = param2?.text {
            
            attributes[paramName] = paramValue

        }

     
        let treatment = try! client.getTreatment(split: "natalia-split", atributtes: attributes)
        
        treatmentResult?.text = treatment
    }
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let config = SplitClientConfig(featuresRefreshRate: 30, segmentsRefreshRate: 30, blockUntilReady: 50000)
//        let authorizationKey = "k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq"
//
//        let key: Key = Key(matchingKey: "Mozi", trafficType: "user", bucketingKey: "lala")
//
//        guard let splitFactory = try? SplitFactory(apiToken: authorizationKey, key: key, config: config) else {
//            return
//        }
//
//        let client = splitFactory.client()
//
//
//        let names: [String] = ["nati","Mozi","Guille","mozi"]
//        var attributes: [String:Any] = [:]
//        attributes["name"] = names
//
//        let treatment = try! client.getTreatment(split: "natalia-split", atributtes: attributes)
//
////        if treatment == "ViewLoginA" {
////
////            self.selectedIndex = 0
////
////        } else {
////
////            self.selectedIndex = 1
////
////        }
//        debugPrint()
////        debugPrint(client.getTreatment(key: key,split: "natalia-split"))
////        debugPrint(client.getTreatment(key: key,split: "natalia-split"))
////        debugPrint(client.getTreatment(key: key,split: "natalia-split"))
////        let result = client.getTreatment(key: key, split: "natalia-split", atributtes: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

