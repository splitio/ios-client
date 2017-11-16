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
        
        let config = SplitClientConfig(featuresRefreshRate: 5, segmentsRefreshRate: 5, blockUntilReady: 50000)
        guard let splitFactory = try? SplitFactory(apiToken: "k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq", config: config) else {
            return
        }
        let client = splitFactory.client()
        
        let key: Key = Key(matchingKey: "Mozi", trafficType: "user", bucketingKey: "lala")

        debugPrint(client.getTreatment(key: "Mozi",split: "mozilla-split"))
        debugPrint(client.getTreatment(key: key,split: "natalia-split"))
        debugPrint(client.getTreatment(key: key,split: "natalia-split"))
        debugPrint(client.getTreatment(key: key,split: "natalia-split"))
        let result = client.getTreatment(key: key, split: "natalia-split", atributtes: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

