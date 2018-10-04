//
//  MetricsManager.swift
//  Split
//
//  Created by Javier Avrudsky on 09/28/2018.
//

import Foundation

struct MetricManagerConfig {
    var pushRate: Int! // Interval
}

class MetricsManager: PeriodicDataTask {
    
    private var currentCountersHit = SingleDictionaryWrapper<String, MetricCounter>()
    private var currentTimesHit = SingleDictionaryWrapper<String, MetricTime>()
    
    private let kTimesFile = "timesFile"
    private let kCountersFile = "countersFile"
    
    init(config: MetricManagerConfig) {
        super.init()
    }
    
    override func saveDataToDisk() {
        saveTimesToDisk()
        saveCountersToDisk()
    }
    
    override func loadDataFromDisk(){
        loadTimesFile()
        loadCountersFile()
    }
    
    override func executePeriodicAction() {
        
    }
}

// MARK: Public
extension MetricsManager {
    
    func time(microseconds latency: Int64, for operationName: String) {
        var time: MetricTime
        if let t = currentTimesHit.value(forKey: operationName) {
            time = t
        } else {
            time = MetricTime(name: operationName)
        }
        time.addLatency(microseconds: latency)
        currentTimesHit.setValue(time, toKey: operationName)
    }
    
    func count(delta: Int64, for counterName: String) {
        var counter: MetricCounter
        if let c = currentCountersHit.value(forKey: counterName) {
            counter = c
        } else {
            counter = MetricCounter(name: counterName)
        }
        counter.addDelta(delta)
        currentCountersHit.setValue(counter, toKey: counterName)
    }
    
    func gauge(value: Double, for gauge: String) {
        
    }
    
    func appendHitAndSendAll(){
        
        sendMetrics()
    }
}

// MARK: Private
extension MetricsManager {
    
    
    private func sendMetrics() {
        /*
        for (_, metricsHit) in metricsHits {
            sendMetrics(metricsHit: metricsHit)
        }
 */
    }
    
    private func loadTimesFile() {
        guard let jsonContent = loadFileContent(fileName: kTimesFile) else {
            return
        }
        do {
            let times = try Json.encodeFrom(json: jsonContent, to: [MetricTime].self)
            currentTimesHit = SingleDictionaryWrapper()
            for time in times {
                currentTimesHit.setValue(time, toKey: time.name)
            }
        } catch {
            Logger.e("Error while loading time metrics from disk")
            return
        }
    }
    
    private func loadCountersFile() {
        guard let jsonContent = loadFileContent(fileName: kCountersFile) else {
            return
        }
        do {
            let counters = try Json.encodeFrom(json: jsonContent, to: [MetricCounter].self)
            currentCountersHit = SingleDictionaryWrapper()
            for counter in counters {
                currentCountersHit.setValue(counter, toKey: counter.name)
            }
        } catch {
            Logger.e("Error while loading metrics counters from disk")
            return
        }
    }

    private func saveTimesToDisk() {
        if currentTimesHit.count > 0 {
            do {
                let times = currentTimesHit.all.values.map { $0 }
                let jsonData = try Json.encodeToJson(times)
                saveFileContent(fileName: kTimesFile, content: jsonData)
            } catch {
                Logger.e("Could not save metrics times)")
            }
        }
    }
    
    private func saveCountersToDisk() {
        if currentCountersHit.count > 0 {
            do {
                let counters = currentCountersHit.all.values.map { $0 }
                let jsonData = try Json.encodeToJson(counters)
                saveFileContent(fileName: kCountersFile, content: jsonData)
            } catch {
                Logger.e("Could not save metrics counters)")
            }
        }
    }
}
