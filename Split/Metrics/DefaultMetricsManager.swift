//
//  MetricsManager.swift
//  Split
//
//  Created by Javier Avrudsky on 09/28/2018.
//

import Foundation

protocol MetricsManager {
    func time(microseconds latency: Int64, for operationName: String)
    func count(delta: Int64, for counterName: String)
    func flush()
}

struct Metrics {
    struct Time {
        static let getTreatment = "sdk.getTreatment"
        static let getTreatments = "sdk.getTreatments"
        static let getTreatmentWithConfig = "sdk.getTreatmentWithConfig"
        static let getTreatmentsWithConfig = "sdk.getTreatmentsWithConfig"
        static let sdkReady = "sdk.ready"
        static let splitChangeFetcherGet = "splitChangeFetcher.time"
        static let mySegmentsFetcherGet = "mySegmentsFetcher.time"
    }

    struct Counter {
        static let getApiKeyFromSecureStorage = "sdk.getApiKeyFromSecureStorage"
        static let splitChangeFetcherStatus200 = "splitChangeFetcher.status.200"
        static let splitChangeFetcherException = "splitChangeFetcher.exception"
        static let mySegmentsFetcherStatus200 = "mySegmentsFetcher.status.200"
        static let mySegmentsFetcherException = "mySegmentsFetcher.exception"
    }
}

class MetricManagerConfig {
    static let  `default`: MetricManagerConfig = {
        return MetricManagerConfig()
    }()
    var pushRateInSeconds: Int = 1800
    var defaultDataFolderName: String = "split_data"
}

class DefaultMetricsManager {

    private var lastPostTime: Int64 = Date().unixTimestamp()
    private var countersCache = SynchronizedArrayWrapper<CounterMetricSample>()
    private var timesCache = SynchronizedArrayWrapper<TimeMetricSample>()

    private let kTimesFile = "timesFile"
    private let kCountersFile = "countersFile"
    private let pushRateInSeconds: Int
    private let restClient: MetricsRestClient
    private let fileStorage: FileStorageProtocol

    /***
     * Shared instance to use within all app
     * It can be used with a default config
     * Constructors remain interna so that the manager can
     * can be used with a custom config
     */
    static let shared: DefaultMetricsManager = {
        let instance = DefaultMetricsManager()
        return instance
    }()

    convenience init(config: MetricManagerConfig = MetricManagerConfig.default) {
        self.init(config: config, restClient: RestClient())
    }

    init(config: MetricManagerConfig, restClient: MetricsRestClient) {
        self.restClient = restClient
        self.fileStorage = FileStorage(dataFolderName: config.defaultDataFolderName)
        self.pushRateInSeconds = config.pushRateInSeconds
    }

    private func saveDataToDisk() {
        saveTimesToDisk()
        saveCountersToDisk()
    }

    private func loadDataFromDisk() {
        loadTimesFile()
        loadCountersFile()
    }

    private func sendDataToServer() {
        sendTimes()
        sendCounters()
    }
}

// MARK: Public
extension DefaultMetricsManager {

    func time(microseconds latency: Int64, for operationName: String) {
        timesCache.append(TimeMetricSample(operation: operationName, latency: latency))
        if shouldPostToServer() {
            sendDataToServer()
        }
    }

    func count(delta: Int64, for counterName: String) {
        countersCache.append(CounterMetricSample(name: counterName, delta: delta))
        if shouldPostToServer() {
            sendDataToServer()
        }
    }

    func flush() {
        sendDataToServer()
    }
}

// MARK: Private - Common
extension DefaultMetricsManager {
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
extension DefaultMetricsManager {

    private func sendTimes() {
        if timesCache.count == 0 { return }
        let timeSamples = timesCache.all
        timesCache.removeAll()
        if restClient.isSdkServerAvailable() {
            restClient.sendTimeMetrics(buildTimesToSend(timeSamples: timeSamples), completion: { result in
                do {
                    _ = try result.unwrap()
                    Logger.d("Time metrics posted successfully")
                } catch {
                    self.timesCache.append(timeSamples)
                    Logger.e("Time metrics error: \(String(describing: error))")
                }
            })
        } else {
            Logger.d("Server is not reachable. Sending time metrics will be delayed until host is reachable")
        }
    }

    private func buildTimesToSend(timeSamples: [TimeMetricSample]) -> [TimeMetric] {
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
extension DefaultMetricsManager {

    private func sendCounters() {
        if countersCache.count == 0 { return }
        let counterSamples = countersCache.all
        countersCache.removeAll()

        if restClient.isSdkServerAvailable() {
            restClient.sendCounterMetrics(buildCountersToSend(counterSamples: counterSamples), completion: { result in
                do {
                    _ = try result.unwrap()
                    Logger.d("Counter metrics posted successfully")
                } catch {
                    self.countersCache.append(counterSamples)
                    Logger.e("Counter metrics error: \(String(describing: error))")
                }
            })
        } else {
            Logger.d("Server is not reachable. Sending count metrics will be delayed until host is reachable")
        }
    }

    private func buildCountersToSend(counterSamples: [CounterMetricSample]) -> [CounterMetric] {
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

// MARK: Helpers - Internal not overridable
extension DefaultMetricsManager {
    func loadFileContent(fileName: String, removeAfter: Bool = true) -> String? {
        guard let fileContent = fileStorage.read(fileName: fileName) else {
            return nil
        }
        if fileContent.count == 0 { return nil }
        if removeAfter {
            fileStorage.delete(fileName: fileName)
        }
        return fileContent
    }

    func saveFileContent(fileName: String, content: String) {
        fileStorage.write(fileName: fileName, content: content)
    }
}

// MARK: Background / Foreground
extension DefaultMetricsManager {

    private func subscribeNotifications() {
        NotificationHelper.instance.addObserver(for: AppNotification.didBecomeActive) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.loadDataFromDisk()
        }

        NotificationHelper.instance.addObserver(for: AppNotification.didEnterBackground) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.saveDataToDisk()
        }
    }
}
