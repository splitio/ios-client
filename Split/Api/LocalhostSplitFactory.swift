//
//  LocalhostSplitFactory.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
 Default implementation of SplitManager protocol
 */
public class LocalhostSplitFactory: NSObject, SplitFactory {
    
    private let localhostClient: SplitClient
    private let localhostManager: SplitManager
    
    public var client: SplitClient {
        return localhostClient
    }
    
    public var manager: SplitManager {
        return localhostManager
    }
    
    public var version: String {
        return Version.toString()
    }
    
    init(config: SplitClientConfig) {
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)
        MetricManagerConfig.default.pushRateInSeconds = config.metricsPushRate
    
        let treatmentFetcher: TreatmentFetcher = LocalhostTreatmentFetcher()
        localhostClient = LocalhostSplitClient(treatmentFetcher: treatmentFetcher)
        localhostManager = LocalhostSplitManager(treatmentFetcher: treatmentFetcher)
    }
    
}
