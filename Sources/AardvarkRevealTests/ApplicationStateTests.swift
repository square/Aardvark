//
//  Copyright 2020 Square, Inc.
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

import XCTest

@testable import AardvarkReveal

final class ApplicationStateTests: XCTestCase {

    func testDecodesClassFromJSON() throws {
        let json = """
            {
              "n": "UIWindowLayer",
              "s": {
                "n": "CALayer",
                "s": {
                  "n": "NSObject"
                }
              }
            }
            """

        let decoder = JSONDecoder()
        let parsedClass = try decoder.decode(Class.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(
            parsedClass,
            .subclass(
                name: "UIWindowLayer",
                superclass: .subclass(
                    name: "CALayer",
                    superclass: .baseClass(name: "NSObject")
                )
            )
        )
    }

    func testDecodesSimpleObjectFromJSON() throws {
        let json = """
            {
              "at": {},
              "i": 2651332643815161859,
              "c": {
                "n": "UIDevice",
                "s": {
                  "n": "NSObject"
                }
              },
              "a": "0x600003354040"
            }
            """

        let decoder = JSONDecoder()
        let parsedObject = try decoder.decode(Object.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(
            parsedObject,
            Object(
                identifier: 2651332643815161859,
                class: .subclass(name: "UIDevice", superclass: .baseClass(name: "NSObject")),
                attributes: [:]
            )
        )
    }

    func testDecodesObjectAttributeFromJSON() throws {
        let json = """
            {
              "c": "UIWindow",
              "t": "NSObject",
              "v": {
                "at": {},
                "i": 2651332643815161927,
                "c": {
                  "n": "NSObject"
                },
                "a": "0x6000033f5160"
              }
            }
            """

        let decoder = JSONDecoder()
        let parsedAttribute = try decoder.decode(Attribute.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(
            parsedAttribute,
            .object(
                Object(
                    identifier: 2651332643815161927,
                    class: .baseClass(name: "NSObject"),
                    attributes: [:]
                )
            )
        )
    }

    func testDecodesNullObjectAttributeFromJSON() throws {
        let json = """
            {
              "c": "UIWindow",
              "t": "NSObject",
              "v": null
            }
            """

        let decoder = JSONDecoder()
        let parsedAttribute = try decoder.decode(Attribute.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(
            parsedAttribute,
            .unknown
        )
    }

    func testDecodesArrayAttributeFromJSON() throws {
        let json = """
            {
                "c": "UIWindow",
                "t": "NSArray",
                "v": [
                    {
                        "at": {},
                        "i": 2651332643815161927,
                        "c": {
                          "n": "NSObject"
                        },
                        "a": "0x6000033f5160"
                    },
                    {
                        "at": {},
                        "i": 2651332643815161928,
                        "c": {
                          "n": "NSObject"
                        },
                        "a": "0x6000033f5160"
                    }
                ]
            }
            """

        let decoder = JSONDecoder()
        let parsedAttribute = try decoder.decode(Attribute.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(
            parsedAttribute,
            .array(
                [
                    Object(
                        identifier: 2651332643815161927,
                        class: .baseClass(name: "NSObject"),
                        attributes: [:]
                    ),
                    Object(
                        identifier: 2651332643815161928,
                        class: .baseClass(name: "NSObject"),
                        attributes: [:]
                    ),
                ]
            )
        )
    }

}
