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
    
    var previousMatchingKey: String?
    var previousBucketingKey: String?

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
    }
    
    func configure() {
        var bucketing: String?
        let sRate = 30
        let mySegRate = 30
        let matchingKeyText: String = (matchingKey?.text)!
        bucketing = bucketkey?.text
        
        if(matchingKeyText != previousMatchingKey || bucketing != previousBucketingKey){
            
            self.previousMatchingKey = matchingKeyText
            self.previousBucketingKey = bucketing
            
            var myDict: NSDictionary?
            var authorizationKey: String?
            if let path = Bundle.main.path(forResource: "configuration", ofType: "plist") {
                myDict = NSDictionary(contentsOfFile: path)
            }
            if let dict = myDict {
                for key in dict.allKeys {
                    let value = dict[key] as? String
                    authorizationKey = value
                }
            }
           
            let config = SplitClientConfig()
                .featuresRefreshRate(sRate)
                .segmentsRefreshRate(mySegRate)
                .debugEnabled(false)
                .verboseEnabled(false)
                .blockUntilReady(15000)
                .impressionRefreshRate(10)
                .sdkUrl("https://sdk-aws-staging.split.io/api")
                .eventsUrl("https://events-aws-staging.split.io/api")
            
            let key: Key = Key(matchingKey: matchingKeyText, bucketingKey: bucketing)
            let splitFactory = SplitFactory(apiKey: authorizationKey!, key: key, config: config)
            
            
            self.factory = splitFactory
            self.client = splitFactory.client()
        }
    }
    
    
    func treatment() {
        
        var atributtes: [String:Any]?
        if let json = param1?.text {
           atributtes = convertToDictionary(text: json)
           print(atributtes)
        }
        
        let treatment = try! client?.getTreatment(split: (splitName?.text)!, atributtes: atributtes)
        treatmentResult?.text = treatment
    }
    
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
}

