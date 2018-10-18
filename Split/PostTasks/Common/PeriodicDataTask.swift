//
//  PeriodicDataTask.swift
//  Split
//
//  Created by Javier on 01/10/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class PeriodicDataTask: PeriodicDataTaskProtocol {
    
    private var maxHitAttempts = 3
    private var firstPushWindowInSecs: Int = 0
    private var pushRateInSecs: Int = 1800
    private var queueSize: Int64 = -1 // No queue size
    private var itemsPerPush: Int = -1 // No item per push limit
    private var pollingManager: PollingManager!
    
    private var fileStorage = FileStorage()
    
    init() {
        createPollingManager()
        subscribeNotifications()
    }
    
    deinit {
        #if swift(>=4.2)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        #else
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        #endif
    }
    
    func start(){
        pollingManager.start()
    }
    
    func stop(){
        pollingManager.stop()
    }
    
    func executePeriodicAction() {
        print("executePeriodicAction - method not implemented")
    }
    
    func loadDataFromDisk() {
        print("loadDataFromDisk - method not implemented")
    }
    
    func saveDataToDisk() {
        print("saveDataToDisk - method not implemented")
    }
}

// MARK: Helpers - Internal not overridable
extension PeriodicDataTask {
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
        fileStorage.save(fileName: fileName, content: content)
    }
}

// MARK: Private
extension PeriodicDataTask {
    private func createPollingManager(){
        var config = PollingManagerConfig()
        config.firstPollWindow = self.firstPushWindowInSecs
        config.rate = self.pushRateInSecs
        
        pollingManager = PollingManager(
            dispatchGroup: nil,
            config: config,
            triggerAction: {[weak self] in
                if let strongSelf = self {
                    strongSelf.executePeriodicAction()
                }
            }
        )
    }
}

// MARK: Background / Foreground
extension PeriodicDataTask {
    @objc func applicationDidEnterBackground() {
        saveDataToDisk()
    }
    
    @objc func applicationDidBecomeActive() {
        loadDataFromDisk()
    }
    
    func subscribeNotifications() {
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        #else
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        #endif
    }
}
