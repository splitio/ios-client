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
    
    var factory: SplitFactory?
    var client: SplitClientTreatmentProtocol?

    @IBAction func evaluate(_ sender: Any) {
    
        configure()
        treatment()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // configure()
    }
    
    func configure() {
        
        var bucketing: String?
        
        let splitRate: String  = (splitRefreshRate?.text)!
        let sRate = Int(splitRate)
        
        let mySegmentRate: String  = (mySegmentRefreshRate?.text)!
        let mySegRate = Int(mySegmentRate)
        
        let matchingKeyText: String = (matchingKey?.text)!
        
        
        if let bucketingKeyTexy = bucketkey?.text {
            
            bucketing = bucketingKeyTexy
            
        } else {
            
            bucketing = matchingKey?.text
            
        }
        
        let authorizationKey = apiKey?.text //"k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq"
        
        let config = SplitClientConfig(featuresRefreshRate: sRate, segmentsRefreshRate: mySegRate, blockUntilReady: 50000, environment: SplitEnvironment.Staging, apiKey: authorizationKey!)
        
        
        let key: Key = Key(matchingKey: matchingKeyText, trafficType: "user", bucketingKey: bucketing)
        
        //let key: Key = Key(matchingKey: "mozi", trafficType: "user", bucketingKey: "mozi")
        
        
        guard let splitFactory = try? SplitFactory(key: key, config: config) else {
            return
        }
        
        self.factory = splitFactory
        
        self.client = splitFactory.client()
        
    }
    
    
    func treatment() {
        
        
        var attributes: [String:Any] = [:]
        
        if let paramName = param1?.text, let paramValue = param2?.text {
            
            attributes[paramName] = paramValue
            
        }
        
        let treatment = try! client?.getTreatment(split: (splitName?.text!)!, atributtes: attributes)
        
        treatmentResult?.text = treatment
        
    }
    
    
}

