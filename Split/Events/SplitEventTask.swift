//
//  SplitEventTask.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/11/18.
//

import Foundation

//open class SplitEventTask: NSObject {
//    public var event: SplitEvent?
//    @objc open func onPostExecute(client: SplitClient) {
//        debugPrint("* running superclass.onPostExecute. This method should be override by developers")
//    }
//
//    @objc open func onPostExecuteView(client: SplitClient) {
//        debugPrint("* running superclass.onPostExecuteView. This method should be override by developers")
//    }
//}

protocol SplitEventTask {
    var event: SplitEvent { get }
    var runInBackground: Bool { get }
    func takeQueue() -> DispatchQueue?
    func run()
}
