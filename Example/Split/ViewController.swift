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
    }
    
    func configure() {
        
        var bucketing: String?
        
       // let splitRate: String  = (splitRefreshRate?.text)!
        let sRate = 30//Int(splitRate)
        
      //  let mySegmentRate: String  = (mySegmentRefreshRate?.text)!
        let mySegRate = 30//Int(mySegmentRate)
        
        let matchingKeyText: String = (matchingKey?.text)!
        
        
        if let bucketingKeyTexy = bucketkey?.text {
            
            bucketing = bucketingKeyTexy
            
        } else {
            
            bucketing = matchingKey?.text
            
        }
        
        var myDict: NSDictionary?
        var authorizationKey: String?
        if let path = Bundle.main.path(forResource: "configuration", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
           
            for key in dict.allKeys {
                
                let value = dict[key] as? String
                
                authorizationKey = value
              
                debugPrint(value)
                
            }
            
        }
        
        let config = SplitClientConfig(featuresRefreshRate: sRate, segmentsRefreshRate: mySegRate, blockUntilReady: 50000, environment: SplitEnvironment.Staging, apiKey: authorizationKey!)
        
        
        let key: Key = Key(matchingKey: matchingKeyText, trafficType: "user", bucketingKey: bucketing)
      
    
        guard let splitFactory = try? SplitFactory(key: key, config: config) else {
            return
        }
        
        self.factory = splitFactory
        
        self.client = splitFactory.client()
        
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

