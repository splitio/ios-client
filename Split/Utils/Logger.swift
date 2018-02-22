//
//  Logger.swift
//  Split
//
//  Created by Sebastian Arrubia on 2/21/18.
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
    
    private let TAG:String = "SplitSDK";
    
    private var _debugOn:Bool = false;
    
    static let shared: Logger = {
        let instance = Logger()
        return instance
    }()
    
    //Guarantee singleton instance
    private init(){}
    
    public func debugLevel(debug:Bool){
        objc_sync_enter(self)
        _debugOn = debug
        objc_sync_exit(self)
    }
    
    private func log(level:Logger.Level, msg:String, _ ctx:Any ...){
        
        if(!_debugOn && (level == Logger.Level.VERBOSE || level == Logger.Level.DEBUG)){
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
