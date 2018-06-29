//
//  PollingManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/18/18.
//

import Foundation

struct PollingManagerConfig {
    var firstPollWindow: Int?
    var rate: Int = 10
}

typealias PollingTriggerAction = ()->Void
protocol PollingManagerProtocol {
    func start()
    func stop()
}

class PollingManager: PollingManagerProtocol {
    
    /* public weak ??? */ private var dispatchGroup: DispatchGroup?
    private var firstPollWindow: Int = 0
    private var rate: Int
    private var triggerAction: PollingTriggerAction
    private var pollTimer: DispatchSourceTimer?
    
    init(dispatchGroup: DispatchGroup?, config: PollingManagerConfig, triggerAction: @escaping PollingTriggerAction){
        self.dispatchGroup = dispatchGroup
        self.rate = config.rate
        if let firstPollWindow = config.firstPollWindow {
            self.firstPollWindow = firstPollWindow
        }
        self.triggerAction = triggerAction
    }
    
    func start(){
        startPolling()
    }
    
    func stop(){
        stopPolling()
    }
    
    private func startPolling() {
        let queue = DispatchQueue(label: "split-polling-queue")
        pollTimer = DispatchSource.makeTimerSource(queue: queue)
        pollTimer!.schedule(deadline: .now() + .seconds(self.firstPollWindow), repeating: .seconds(self.rate))
        pollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.pollTimer != nil else {
                strongSelf.stopPolling()
                return
            }
            strongSelf.triggerPollAction()
        }
        pollTimer!.resume()
    }
    
    private func stopPolling() {
        pollTimer?.cancel()
        pollTimer = nil
    }
    
    private func triggerPollAction() {
        
        dispatchGroup?.enter()
        let queue = DispatchQueue(label: "split-event-queue")
        queue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.triggerAction()
            strongSelf.dispatchGroup?.leave()
        }
    }
    
}
