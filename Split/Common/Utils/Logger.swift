//
//  Logger.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/5/18.
//

import Foundation

class Logger {
    
    private let queueName = "split.logger-queue"
    private var queue: DispatchQueue
    private let TAG:String = "SplitSDK"
    
    private var isVerboseEnabled = false
    private var isDebugEnabled = false
    
    enum Level : String {
        case VERBOSE="VERBOSE"
        case DEBUG="DEBUG"
        case INFO="INFO"
        case WARNING="WARNING"
        case ERROR="ERROR"
    }
    
    var isVerboseModeEnabled: Bool {
        set {
            queue.async(flags: .barrier) {
                self.isVerboseEnabled = newValue
            }
        }
        get {
            var isEnabled = false
            queue.sync {
                isEnabled = self.isVerboseEnabled
            }
            return isEnabled
        }
    }
    
    var isDebugModeEnabled: Bool {
        set {
            queue.async(flags: .barrier) {
                self.isDebugEnabled = newValue
            }
        }
        get {
            var isEnabled = false
            queue.sync {
                isEnabled = self.isDebugEnabled
            }
            return isEnabled
        }
    }
    
    static let shared: Logger = {
        let instance = Logger()
        return instance
    }()
    
    //Guarantee singleton instance
    private init(){
        queue = DispatchQueue(label: queueName, attributes: .concurrent)
    }
    
    private func log(level:Logger.Level, msg:String, _ ctx:Any ...){
        
        if(!isDebugModeEnabled && level == Logger.Level.DEBUG){
            return
        }
        
        if(!isVerboseModeEnabled && level == Logger.Level.VERBOSE){
            return
        }
        
        if(ctx.count == 0) {
            print(level.rawValue, self.TAG, msg)
        } else {
            print(level.rawValue, self.TAG, msg, ctx[0])
        }
    }
    
    public static func v(_ message:String, _ context:Any ...){
        context.count > 0
            ? shared.log(level:Logger.Level.VERBOSE, msg:message, context)
            : shared.log(level:Logger.Level.VERBOSE, msg:message)
    }
    
    public static func d(_ message:String, _ context:Any ...){
        context.count > 0
            ? shared.log(level:Logger.Level.DEBUG, msg:message, context)
            : shared.log(level:Logger.Level.DEBUG, msg:message)
    }
    
    public static func i(_ message:String, _ context:Any ...){
        context.count > 0
            ? shared.log(level:Logger.Level.INFO, msg: message, context)
            : shared.log(level:Logger.Level.INFO, msg: message)
    }
    
    public static func w(_ message:String, _ context:Any ...){
        context.count > 0
            ? shared.log(level:Logger.Level.WARNING, msg: message, context)
            : shared.log(level:Logger.Level.WARNING, msg: message)
    }
    
    public static func e(_ message:String, _ context:Any ...){
        context.count > 0
            ? shared.log(level:Logger.Level.ERROR, msg:message, context)
            : shared.log(level:Logger.Level.ERROR, msg:message)
    }
}
