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

    @IBOutlet weak var bucketkey: UITextField?
    @IBOutlet weak var splitName: UITextField?
    @IBOutlet weak var matchingKey: UITextField?
    @IBOutlet weak var evaluteButton: UIButton?
    @IBOutlet weak var treatmentResult: UILabel?
    @IBOutlet weak var param1: UITextField?
    @IBOutlet weak var sdkVersion: UILabel?
    
    var factory: SplitFactory?
    var client: SplitClientProtocol?

    @IBAction func evaluate(_ sender: Any) {
        configure()
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configure() {
        
        // Your Split API-KEY
        //let authorizationKey: String = "YOUR_API_KEY"
        let authorizationKey: String = "4eri39qiou5ene271kpk1tnlfnfvid89dgab"
        
        //Provided keys from UI
        let matchingKeyText: String = (matchingKey?.text)!
        let bucketing: String? = bucketkey?.text
        
        //Split Configuration
        let config = SplitClientConfig()
        config.featuresRefreshRate(30)
        config.segmentsRefreshRate(30)
        config.impressionRefreshRate(30)
        config.readyTimeOut(15000)
      
      config.sdkEndpoint("https://sdk-aws-staging.split.io/api")
      config.eventsEndpoint("https://events-aws-staging.split.io/api")
        
        //User Key
        let key: Key = Key(matchingKey: matchingKeyText, bucketingKey: bucketing)
      
        //Split Factory
        self.factory = SplitFactory(apiKey: authorizationKey, key: key, config: config)
        
        //Split Client
        self.client = self.factory?.client()
        
        let task = MyTaskOnReady(vc:self)
        let taskTimedOut = MyTaskOnReadyTimedOut(vc:self)
        
        self.client?.on(SplitEvent.sdkReady, task)
        self.client?.on(SplitEvent.sdkReadyTimedOut, taskTimedOut)
        
        //Showing sdk version in UI
        self.sdkVersion?.text = "SDK Version: \(self.factory?.version() ?? "unknown") "
        
        
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

