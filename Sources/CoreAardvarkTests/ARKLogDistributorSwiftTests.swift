//
//  Copyright 2021 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CoreAardvark
import XCTest

final class ARKLogDistributorSwiftTests: XCTestCase {

    func test_log_propogatesExpectedDefaultValues() throws {
        let logDistributor = ARKLogDistributor()
        let observer = TestObserver()
        logDistributor.add(observer)

        logDistributor.log("Hello world")

        let distributeExpectation = expectation(description: "distributes log message")
        logDistributor.distributeAllPendingLogs {
            distributeExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertEqual(observer.observedLogMessages.count, 1)

        let logMessage = try XCTUnwrap(observer.observedLogMessages.first)
        XCTAssertEqual(logMessage.text, "Hello world")
        XCTAssertEqual(logMessage.type, .default)
        XCTAssertEqual(logMessage.image, nil)
        XCTAssertEqual(logMessage.parameters, [:])
        XCTAssert(logMessage.userInfo.isEmpty)
    }

    func test_log_propogatesPassedInValues() throws {
        let logDistributor = ARKLogDistributor()
        let observer = TestObserver()
        logDistributor.add(observer)

        logDistributor.log(
            "Hello world",
            type: .error,
            image: UIImage(),
            parameters: ["Foo": "Bar"],
            userInfo: ["Test": "Testing"]
        )

        let distributeExpectation = expectation(description: "distributes log message")
        logDistributor.distributeAllPendingLogs {
            distributeExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertEqual(observer.observedLogMessages.count, 1)

        let logMessage = try XCTUnwrap(observer.observedLogMessages.first)
        XCTAssertEqual(logMessage.text, "Hello world")
        XCTAssertEqual(logMessage.type, .error)
        XCTAssertEqual(logMessage.image, UIImage())
        XCTAssertEqual(logMessage.parameters, ["Foo": "Bar"])
        XCTAssertFalse(logMessage.userInfo.isEmpty)
    }

}

// MARK: -

private final class TestObserver: NSObject, ARKLogObserver {

    // MARK: - Public Properties

    private(set) var observedLogMessages: [ARKLogMessage] = []

    // MARK: - ARKLogObserver

    var logDistributor: ARKLogDistributor?

    func observe(_ logMessage: ARKLogMessage) {
        observedLogMessages.append(logMessage)
    }

}
