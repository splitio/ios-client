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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let config = SplitClientConfig(pollForFeatureChangesInterval: 5, blockUntilReady: 5000)
        let trafficType = TrafficType(matchingKey: "test", type: "user")
        try? SplitClient.shared.initialize(withConfig: config, andTrafficType: trafficType)
        
        debugPrint(SplitClient.shared.getTreatment(forSplit: "Test"))
        debugPrint(SplitClient.shared.getTreatment(forSplit: "Test2"))
        debugPrint(SplitClient.shared.getTreatment(forSplit: "fsdfsdf"))
        debugPrint(SplitClient.shared.getTreatment(forSplit: "test-net"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

