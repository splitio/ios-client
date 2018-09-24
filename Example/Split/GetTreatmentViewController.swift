//
//  ViewController.swift
//  Split
//
//  Created by Brian Sztamfater on 09/18/2017.
//  Copyright (c) 2017 Split Software. All rights reserved.
//

import UIKit
import Split

class GetTreatmentViewController: UIViewController {
    
    @IBOutlet weak var bucketkey: UITextField?
    @IBOutlet weak var splitName: UITextField?
    @IBOutlet weak var matchingKey: UITextField?
    @IBOutlet weak var evaluteButton: UIButton?
    @IBOutlet weak var treatmentResult: UILabel?
    @IBOutlet weak var param1: UITextField?
    @IBOutlet weak var sdkVersion: UILabel?
    @IBOutlet weak var evaluateActivityIndicator: UIActivityIndicatorView!
    
    var factory: SplitFactory?
    var client: SplitClientProtocol?
    var manager: SplitManagerProtocol?

    @IBAction func evaluate(_ sender: Any) {
        evaluate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(){
        self.view.endEditing(true)
    }
    
    func evaluate() {
        // Your Split API-KEY - Change in Config.swift file
        let authorizationKey: String = "YOUR_API_KEY"
        
        //Provided keys from UI
        let matchingKeyText: String = (matchingKey?.text)!
        let bucketing: String? = bucketkey?.text
        
        //Split Configuration
        let config = SplitClientConfig()
        
        config.featuresRefreshRate = 30
        config.segmentsRefreshRate = 30
        config.impressionRefreshRate = 30
        config.sdkReadyTimeOut = 15000
        config.connectionTimeout = 50



        config.impressionListener = { impression in
            print("\(impression.keyName ?? "") - \(impression.treatment ?? "") - \(impression.label ?? "")")
            DispatchQueue.global().async {
                // Do some async stuff
            }
        }
        
        //User Key
        let key: Key = Key(matchingKey: matchingKeyText, bucketingKey: bucketing)
        
        //Split Factory
        self.factory = SplitFactory(apiKey: authorizationKey, key: key, config: config)
        
        //Split Client
        self.client = self.factory?.client()
        
        //Split Manager
        self.manager = self.factory?.manager()
        
        //Showing sdk version in UI
        self.sdkVersion?.text = "SDK Version: \(self.factory?.version() ?? "unknown") "
        
        guard let client = self.client else {
            return
        }
        
        self.isEvaluating(active: true)
        client.on(event: SplitEvent.sdkReady) {
            [unowned self, unowned client = client] in
            
            // Main thread stuff
            var attributes: [String:Any]?
            if let json = self.param1?.text {
                attributes = self.convertToDictionary(text: json)
            }
            
            // Evaluate one split
            let treatment = client.getTreatment((self.splitName?.text)!, attributes: attributes)
            self.treatmentResult?.text = treatment
            
            // Get All Splits
            if let manager = self.manager {
                let splits = manager.splits
                splits.forEach {
                    print("SplitView: \($0)")
                }
                
                // Get Splits Names
                let splitNames = manager.splitNames
                splitNames.forEach {
                    print("Split Name: \($0)")
                }
                
                // Find a Split
                if splitNames.count > 0 {
                    let split = manager.split(featureName: splitNames[0])!
                    print("Found Split: \(split)")
                }
            }
            
            self.isEvaluating(active: false)
            DispatchQueue.global().async {
                // Do some async stuff
            }
        }
        
        client.on(event: SplitEvent.sdkReadyTimedOut) {
            [unowned self, unowned client = client] in
            // Main thread stuff
            var attributes: [String:Any]?
            if let json = self.param1?.text {
                attributes = self.convertToDictionary(text: json)
            }
            
            let treatment = client.getTreatment((self.splitName?.text)!, attributes: attributes)
            self.treatmentResult?.text = treatment
            
            self.isEvaluating(active: false)
            DispatchQueue.global().async {
                // Do some async stuff
            }
        }
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
    
    func isEvaluating(active: Bool){
        if active {
            self.evaluateActivityIndicator.startAnimating()
        } else {
            self.evaluateActivityIndicator.stopAnimating()
        }
    }
}
