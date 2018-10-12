//
//  MetricsManager.swift
//  Split
//
//  Created by Javier Avrudsky on 09/28/2018.
//

import Foundation

struct Metrics {
    struct time {
        static let getTreatment = "sdk.getTreatment"
    }
    
    struct counter {
        static let getApiKeyFromSecureStorage = "sdk.getApiKeyFromSecureStorage"
        static let saveApiKeyInSecureStorage = "sdk.saveApiKeyInSecureStorage"
        static let getApiKeyFromSecureStorageCache = "sdk.getApiKeyFromSecureStorageCache"
    }
}

class MetricManagerConfig {
    static let  `default`: MetricManagerConfig = {
        return MetricManagerConfig()
    }()
    var pushRateInSeconds: Int = 1800
}

class MetricsManager: PeriodicDataTask {
    
    private var countersCache = SynchronizedArrayWrapper<CounterMetricSample>()
    private var timesCache = SynchronizedArrayWrapper<TimeMetricSample>()
    
    private let kTimesFile = "timesFile"
    private let kCountersFile = "countersFile"
    
    private var pushRateInSeconds: Int
    private var lastPostTime: Int64 = Date().unixTimestamp()
    private let restClient: MetricsRestClient
    
    /***
     * Shared instance to use within all app
     * It can be used with a default config
     * Constructors remain interna so that the manager can
     * can be used with a custom config
     */
    static let shared: MetricsManager = {
        let config = MetricManagerConfig()
        let instance = MetricsManager(config: config)
        return instance;
    }()
    
    convenience init(config: MetricManagerConfig = MetricManagerConfig.default) {
        self.init(config: config, restClient: RestClient())
    }
    
     init(config: MetricManagerConfig, restClient: MetricsRestClient) {
        pushRateInSeconds = config.pushRateInSeconds
        self.restClient = restClient
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
        sendTimes()
        sendCounters()
    }
}

// MARK: Public
extension MetricsManager {
    
    func time(microseconds latency: Int64, for operationName: String) {
        timesCache.append(TimeMetricSample(operation: operationName, latency: latency))
        if shouldPostToServer() {
            executePeriodicAction()
        }
    }
    
    func count(delta: Int64, for counterName: String) {
        countersCache.append(CounterMetricSample(name: counterName, delta: delta))
        if shouldPostToServer() {
            executePeriodicAction()
        }
    }
}

// MARK: Private - Common
extension MetricsManager {
    private func shouldPostToServer() -> Bool {
        let curTime = Date().unixTimestamp()
        if curTime - lastPostTime >= pushRateInSeconds {
            lastPostTime = curTime
            return true
        }
        return false
    }
}

// MARK: Private - Times
extension MetricsManager {

    private func sendTimes() {
        if timesCache.count == 0 { return }
        let timeSamples = timesCache.all
        timesCache.removeAll()
        if restClient.isSdkServerAvailable() {
            restClient.sendTimeMetrics(buildTimesToSend(timeSamples: timeSamples), completion: { result in
                do {
                    let _ = try result.unwrap()
                    Logger.d("Time metrics posted successfully")
                } catch {
                    self.timesCache.append(timeSamples)
                    Logger.e("Time metrics error: \(String(describing: error))")
                }
            })
        }
    }

    private func buildTimesToSend(timeSamples: [TimeMetricSample]) -> [TimeMetric]{
        var times = [String: TimeMetric]()
        for sample in timeSamples {
            let time = times[sample.operation] ?? TimeMetric(name: sample.operation)
            time.addLatency(microseconds: sample.latency)
            times[sample.operation] = time
        }
        return times.values.map { return $0 }
    }
    
    private func saveTimesToDisk() {
        if timesCache.count > 0 {
            do {
                let times: [TimeMetricSample] = timesCache.all
                let jsonData = try Json.encodeToJson(times)
                saveFileContent(fileName: kTimesFile, content: jsonData)
            } catch {
                Logger.e("Could not save metrics times)")
            }
        }
    }
    
    private func loadTimesFile() {
        guard let jsonContent = loadFileContent(fileName: kTimesFile) else {
            return
        }
        do {
            let times = try Json.encodeFrom(json: jsonContent, to: [TimeMetricSample].self)
            timesCache = SynchronizedArrayWrapper()
            for time in times {
                timesCache.append(time)
            }
        } catch {
            Logger.e("Error while loading time metrics from disk")
            return
        }
    }
}

// MARK: Private - Counters
extension MetricsManager {
    
    private func sendCounters() {
        if countersCache.count == 0 { return }
        let counterSamples = countersCache.all
        countersCache.removeAll()
        
        if restClient.isSdkServerAvailable() {
            restClient.sendCounterMetrics(buildCountersToSend(counterSamples: counterSamples), completion: { result in
                do {
                    let _ = try result.unwrap()
                    Logger.d("Counter metrics posted successfully")
                } catch {
                    self.countersCache.append(counterSamples)
                    Logger.e("Counter metrics error: \(String(describing: error))")
                }
            })
        }
    }
    
    private func buildCountersToSend(counterSamples: [CounterMetricSample]) -> [CounterMetric]{
        var counters = [String: CounterMetric]()
        for sample in counterSamples {
            var counter = counters[sample.name] ?? CounterMetric(name: sample.name)
            counter.addDelta(sample.delta)
            counters[sample.name] = counter
        }
        return counters.values.map { return $0 }
    }
    
    private func saveCountersToDisk() {
        if countersCache.count > 0 {
            do {
                let counters: [CounterMetricSample] = countersCache.all
                let jsonData = try Json.encodeToJson(counters)
                saveFileContent(fileName: kCountersFile, content: jsonData)
            } catch {
                Logger.e("Could not save metrics counters)")
            }
        }
    }
    
    private func loadCountersFile() {
        guard let jsonContent = loadFileContent(fileName: kCountersFile) else {
            return
        }
        do {
            let counters = try Json.encodeFrom(json: jsonContent, to: [CounterMetricSample].self)
            countersCache = SynchronizedArrayWrapper<CounterMetricSample>()
            for counter in counters {
                countersCache.append(counter)
            }
        } catch {
            Logger.e("Error while loading metrics counters from disk")
            return
        }
    }
}
