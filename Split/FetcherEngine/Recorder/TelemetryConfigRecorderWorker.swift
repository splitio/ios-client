//
//  TelemetryConfigRecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

class TelemetryConfigRecorderWorker: RecorderWorker {

    private let configRecorder: HttpTelemetryConfigRecorder
    private let telemetryConsumer: TelemetryConsumer
    private let splitConfig: SplitClientConfig

    init(telemetryConfigRecorder: HttpTelemetryConfigRecorder,
         splitClientConfig: SplitClientConfig,
         telemetryConsumer: TelemetryStorage) {
        self.configRecorder = telemetryConfigRecorder
        self.telemetryConsumer = telemetryConsumer
        self.splitConfig = splitClientConfig
    }

    func flush() {
        var sendCount = 1
        while !send() && sendCount < ServiceConstants.retryCount {
            sendCount+=1
            ThreadUtils.delay(seconds: ServiceConstants.retryTimeInSeconds)
        }
    }

    private func send() -> Bool {
        do {
            _ = try configRecorder.execute(buildTelemetryConfig())
            Logger.d("Telemetry config posted successfully")
        } catch let error {
            Logger.e("Telemetry config: \(String(describing: error))")
            return false
        }
        return true
    }

    private func buildTelemetryConfig() -> TelemetryConfig {

        let rates = TelemetryRates(splits: splitConfig.featuresRefreshRate,
                                   mySegments: splitConfig.segmentsRefreshRate,
                                   impressions: splitConfig.impressionRefreshRate,
                                   events: splitConfig.eventsPushRate,
                                   telemetry: splitConfig.internalTelemetryRefreshRate)

        let endpoints = splitConfig.serviceEndpoints
        let urlOverrides = TelemetryUrlOverrides(sdk: endpoints.isCustomSdkEndpoint,
                                                 events: endpoints.isCustomEventsEndpoint,
                                                 auth: endpoints.isCustomAuthServiceEndpoint,
                                                 stream: endpoints.isCustomStreamingEndpoint,
                                                 telemetry: endpoints.isCustomTelemetryEndpoint)

        return TelemetryConfig(streamingEnabled: splitConfig.streamingEnabled,
                               rates: rates, urlOverrides: urlOverrides,
                               impressionsQueueSize: splitConfig.impressionsQueueSize,
                               eventsQueueSize: splitConfig.eventsQueueSize,
                               impressionsMode: splitConfig.finalImpressionsMode.intValue(),
                               impressionsListenerEnabled: splitConfig.impressionListener != nil,
                               httpProxyDetected: splitConfig.isProxy(),
                               activeFactories: telemetryConsumer.getActiveFactories(),
                               redundantFactories: telemetryConsumer.getRedundantFactories(),
                               timeUntilReady: telemetryConsumer.getTimeUntilReady(),
                               timeUntilReadyFromCache: telemetryConsumer.getTimeUntilReadyFromCache(),
                               nonReadyUsages: telemetryConsumer.getNonReadyUsages(),
                               integrations: nil, tags: telemetryConsumer.popTags())
    }
}
