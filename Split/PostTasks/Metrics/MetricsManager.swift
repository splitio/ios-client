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
    
    private var pushRateInSecs: Int
    private var lastPostTime: Int64 = Date().unixTimestampInMiliseconds()
    private let restClient = RestClient()
    
    init(config: MetricManagerConfig) {
        pushRateInSecs = config.pushRate
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
        if shouldPostToServer() {
            executePeriodicAction()
        }
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
    
}

// MARK: Private
extension MetricsManager {
    
    
    private func sendTimes() {
        if currentTimesHit.count == 0 { return }
        let times = currentTimesHit.all.map {  key, time in
            return time
        }
        currentTimesHit.removeAll()
        
        if restClient.isSdkServerAvailable() {
            restClient.sendTimeMetrics(times, completion: { result in
                do {
                    let _ = try result.unwrap()
                    Logger.d("Time metrics posted successfully")
                } catch {
                    Logger.e("Time metrics error: \(String(describing: error))")
                    currentTimesHit.A
                }
            })
        }
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
    
    private func shouldPostToServer() -> Bool {
        let curTime = Date().unixTimestamp()
        if curTime - lastPostTime >= pushRateInSecs {
            lastPostTime = curTime
            return true
        }
        return false
    }
}
