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

        let config = SplitClientConfig(pollForFeatureChangesInterval: 5, blockUntilReady: 5000)
        guard let splitFactory = try? SplitFactory(apiToken: "", config: config) else {
            return
        }
        let client = splitFactory.client()
        
        debugPrint(client.getTreatment(forSplit: "Test"))
        debugPrint(client.getTreatment(forSplit: "Test2"))
        debugPrint(client.getTreatment(forSplit: "fsdfsdf"))
        debugPrint(client.getTreatment(forSplit: "test-net"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

