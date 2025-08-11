//
//  SplitClientTests.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10/04/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

class SplitClientTests: XCTestCase {

    var client: SplitClient!
    let key = Key(matchingKey: "key1")
    var treatmentManager: TreatmentManager!
    var apiFacade: SplitApiFacade!
    var storageContainer: SplitStorageContainer!
    var eventsManager: SplitEventsManagerMock!
    var eventsTracker: EventsTrackerStub!
    var clientManager: ClientManagerMock!
    let events: [SplitEvent] = [.sdkReadyFromCache, .sdkReady, .sdkUpdated, .sdkReadyTimedOut]

    override func setUp() {
        storageContainer = TestingHelper.createStorageContainer()
        eventsManager = SplitEventsManagerMock()
        clientManager = ClientManagerMock()
        treatmentManager = TreatmentManagerMock()
        apiFacade = TestingHelper.createApiFacade()
        let config = SplitClientConfig()
        config.logLevel = .verbose
        eventsTracker = EventsTrackerStub()

        client = DefaultSplitClient(config: config, key: key,
                                    treatmentManager: treatmentManager, apiFacade: apiFacade,
                                    storageContainer: storageContainer,
                                    eventsManager: eventsManager,
                                    eventsTracker: eventsTracker, clientManager: clientManager)
    }

    func testOnMain() {
        for event in events {
            client.on(event: event, execute: { print("exec")})
        }

        for event in events {
            guard let task = eventsManager.registeredEvents.first(where: { $0.key.type == event })?.value else {
                XCTAssertTrue(false)
                continue
            }

            XCTAssertEqual(false, task.runInBackground)
            XCTAssertNil(task.takeQueue())
        }
    }

    func testOnBg() {
        for event in events {
            client.on(event: event, runInBackground: true, execute: { print("exec")})
        }

        for event in events {
            guard let task = eventsManager.registeredEvents.first(where: { $0.key.type == event })?.value else {
                XCTAssertTrue(false)
                continue
            }

            XCTAssertEqual(true, task.runInBackground)
            XCTAssertNil(task.takeQueue())
        }
    }

    func testOnQueue() {
        for event in events {
            client.on(event: event, queue: DispatchQueue(label: "queue1"), execute: { print("exec")})
        }

        for event in events {
            guard let task = eventsManager.registeredEvents.first(where: { $0.key.type == event })?.value else {
                XCTAssertTrue(false)
                continue
            }

            XCTAssertEqual(true, task.runInBackground)
            XCTAssertNotNil(task.takeQueue())
        }
    }
    
    func testGetTreatmentWithEvaluationOptions() {
        testEvaluationOptionsPassedCorrectly(
            resetMock: { mock in
                mock.getTreatmentCalled = false
                mock.lastGetTreatmentEvaluationOptions = nil
            },
            callMethod: { options in
                _ = self.client.getTreatment("split1", attributes: nil, evaluationOptions: options)
            },
            verifyMethodCalled: { mock in
                return mock.getTreatmentCalled
            },
            getEvaluationOptions: { mock in
                return mock.lastGetTreatmentEvaluationOptions
            }
        )
    }
    
    func testGetTreatmentWithConfigAndEvaluationOptions() {
        testEvaluationOptionsPassedCorrectly(
            resetMock: { mock in
                mock.getTreatmentWithConfigCalled = false
                mock.lastGetTreatmentWithConfigEvaluationOptions = nil
            },
            callMethod: { options in
                _ = self.client.getTreatmentWithConfig("split1", attributes: nil, evaluationOptions: options)
            },
            verifyMethodCalled: { mock in
                return mock.getTreatmentWithConfigCalled
            },
            getEvaluationOptions: { mock in
                return mock.lastGetTreatmentWithConfigEvaluationOptions
            }
        )
    }
    
    func testGetTreatmentsWithEvaluationOptions() {
        testEvaluationOptionsPassedCorrectly(
            resetMock: { mock in
                mock.getTreatmentsCalled = false
                mock.lastGetTreatmentsEvaluationOptions = nil
            },
            callMethod: { options in
                _ = self.client.getTreatments(splits: ["split1", "split2"], attributes: nil, evaluationOptions: options)
            },
            verifyMethodCalled: { mock in
                return mock.getTreatmentsCalled
            },
            getEvaluationOptions: { mock in
                return mock.lastGetTreatmentsEvaluationOptions
            }
        )
    }
    
    func testGetTreatmentsWithConfigAndEvaluationOptions() {
        testEvaluationOptionsPassedCorrectly(
            resetMock: { mock in
                mock.getTreatmentsWithConfigCalled = false
                mock.lastGetTreatmentsWithConfigEvaluationOptions = nil
            },
            callMethod: { options in
                _ = self.client.getTreatmentsWithConfig(splits: ["split1", "split2"], attributes: nil, evaluationOptions: options)
            },
            verifyMethodCalled: { mock in
                return mock.getTreatmentsWithConfigCalled
            },
            getEvaluationOptions: { mock in
                return mock.lastGetTreatmentsWithConfigEvaluationOptions
            }
        )
    }
    
    func testGetTreatmentsByFlagSetWithEvaluationOptions() {
        testEvaluationOptionsPassedCorrectly(
            resetMock: { mock in
                mock.getTreatmentsByFlagSetCalled = false
                mock.lastGetTreatmentsByFlagSetEvaluationOptions = nil
            },
            callMethod: { options in
                _ = self.client.getTreatmentsByFlagSet("set1", attributes: nil, evaluationOptions: options)
            },
            verifyMethodCalled: { mock in
                return mock.getTreatmentsByFlagSetCalled
            },
            getEvaluationOptions: { mock in
                return mock.lastGetTreatmentsByFlagSetEvaluationOptions
            }
        )
    }
    
    func testGetTreatmentsByFlagSetsWithEvaluationOptions() {
        testEvaluationOptionsPassedCorrectly(
            resetMock: { mock in
                mock.getTreatmentsByFlagSetsCalled = false
                mock.lastGetTreatmentsByFlagSetsEvaluationOptions = nil
            },
            callMethod: { options in
                _ = self.client.getTreatmentsByFlagSets(["set1", "set2"], attributes: nil, evaluationOptions: options)
            },
            verifyMethodCalled: { mock in
                return mock.getTreatmentsByFlagSetsCalled
            },
            getEvaluationOptions: { mock in
                return mock.lastGetTreatmentsByFlagSetsEvaluationOptions
            }
        )
    }
    
    func testGetTreatmentsWithConfigByFlagSetWithEvaluationOptions() {
        testEvaluationOptionsPassedCorrectly(
            resetMock: { mock in
                mock.getTreatmentsWithConfigByFlagSetCalled = false
                mock.lastGetTreatmentsWithConfigByFlagSetEvaluationOptions = nil
            },
            callMethod: { options in
                _ = self.client.getTreatmentsWithConfigByFlagSet("set1", attributes: nil, evaluationOptions: options)
            },
            verifyMethodCalled: { mock in
                return mock.getTreatmentsWithConfigByFlagSetCalled
            },
            getEvaluationOptions: { mock in
                return mock.lastGetTreatmentsWithConfigByFlagSetEvaluationOptions
            }
        )
    }
    
    func testGetTreatmentsWithConfigByFlagSetsWithEvaluationOptions() {
        testEvaluationOptionsPassedCorrectly(
            resetMock: { mock in
                mock.getTreatmentsWithConfigByFlagSetsCalled = false
                mock.lastGetTreatmentsWithConfigByFlagSetsEvaluationOptions = nil
            },
            callMethod: { options in
                _ = self.client.getTreatmentsWithConfigByFlagSets(["set1", "set2"], attributes: nil, evaluationOptions: options)
            },
            verifyMethodCalled: { mock in
                return mock.getTreatmentsWithConfigByFlagSetsCalled
            },
            getEvaluationOptions: { mock in
                return mock.lastGetTreatmentsWithConfigByFlagSetsEvaluationOptions
            }
        )
    }

    override func tearDown() {
    }

    private func verifyProperties(in evaluationOptions: EvaluationOptions?) {
        XCTAssertNotNil(evaluationOptions, "evaluationOptions should be passed to TreatmentManager")
        XCTAssertNotNil(evaluationOptions?.properties, "properties should be passed in evaluationOptions")

        if let properties = evaluationOptions?.properties {
            XCTAssertEqual(properties["string"] as? String, "test")
            XCTAssertEqual(properties["number"] as? Int, 123)
            XCTAssertEqual(properties["boolean"] as? Bool, true)
        }
    }

    private func createTestProperties() -> [String: Any] {
        return [
            "string": "test",
            "number": 123,
            "boolean": true
        ]
    }

    private func testEvaluationOptionsPassedCorrectly(
        resetMock: (TreatmentManagerMock) -> Void,
        callMethod: (EvaluationOptions) -> Void,
        verifyMethodCalled: (TreatmentManagerMock) -> Bool,
        getEvaluationOptions: (TreatmentManagerMock) -> EvaluationOptions?
    ) {
        // Create evaluation options with properties
        let evaluationOptions = EvaluationOptions(properties: createTestProperties())

        // Reset tracking in the mock
        let mockManager = treatmentManager as! TreatmentManagerMock
        resetMock(mockManager)

        // Call the method with evaluationOptions
        callMethod(evaluationOptions)

        // Verify that the TreatmentManager method was called
        XCTAssertTrue(verifyMethodCalled(mockManager))

        // Verify properties were passed correctly
        verifyProperties(in: getEvaluationOptions(mockManager))
    }
}
