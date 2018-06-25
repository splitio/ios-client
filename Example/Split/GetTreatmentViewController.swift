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
    
    @IBAction func evaluate(_ sender: Any) {
        evaluate()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func evaluate() {
        // Your Split API-KEY - Change in Config.swift file
        let authorizationKey: String = "YOUR_API_KEY"
        
        //Provided keys from UI
        let matchingKeyText: String = (matchingKey?.text)!
        let bucketing: String? = bucketkey?.text
        
        //Split Configuration
        let config = SplitClientConfig()
        config.featuresRefreshRate(30)
        config.segmentsRefreshRate(30)
        config.impressionRefreshRate(30)
        config.readyTimeOut(15000)
        
        //User Key
        let key: Key = Key(matchingKey: matchingKeyText, bucketingKey: bucketing)
        
        //Split Factory
        self.factory = SplitFactory(apiKey: authorizationKey, key: key, config: config)
        
        //Split Client
        self.client = self.factory?.client()
        
        //Showing sdk version in UI
        self.sdkVersion?.text = "SDK Version: \(self.factory?.version() ?? "unknown") "
        
        let task = MyTaskOnReady(vc:self)
        let taskTimedOut = MyTaskOnReadyTimedOut(vc:self)
        
        self.client?.on(SplitEvent.sdkReady, task)
        self.client?.on(SplitEvent.sdkReadyTimedOut, taskTimedOut)
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
