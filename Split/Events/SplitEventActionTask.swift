//
//  SplitEventActionTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 7/6/18.
//

import Foundation

class SplitEventActionTask: SplitEventTask {

    private var eventHandler: SplitAction?

    override private init() {
        super.init()
    }

    convenience init(action: @escaping SplitAction) {
        self.init()
        eventHandler = action
    }

    override func onPostExecute(client: SplitClient) {
        // Do nothing
    }

    override func onPostExecuteView(client: SplitClient) {
        eventHandler?()
    }
}
