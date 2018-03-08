//
//  Logger.swift
//  Split
//
//  Created by Sebastian Arrubia on 3/5/18.
//

import Foundation

class Logger {
    
    enum Level : String {
        case VERBOSE="VERBOSE"
        case DEBUG="DEBUG"
        case INFO="INFO"
        case WARNING="WARNING"
        case ERROR="ERROR"
    }
    
    private let locker: NSLock = NSLock()
    
    private let TAG:String = "SplitSDK";
    
    private var _verboseOn:Bool = false;
    
    private var _debugOn:Bool = false;
    
    static let shared: Logger = {
        let instance = Logger()
        return instance
    }()
    
    //Guarantee singleton instance
    private init(){}
    
    public func verboseLevel(verbose:Bool){
        self.locker.lock()
        _verboseOn = verbose
        self.locker.unlock()
    }
    
    public func debugLevel(debug:Bool){
        self.locker.lock()
        _debugOn = debug
        self.locker.unlock()
    }
    
    private func log(level:Logger.Level, msg:String, _ ctx:Any ...){
        
        if(!_debugOn && level == Logger.Level.DEBUG){
            return
        }
        
        if(!_verboseOn && level == Logger.Level.VERBOSE){
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
