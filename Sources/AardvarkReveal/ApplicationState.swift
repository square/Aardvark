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

import Foundation

enum Class: Equatable {

    case baseClass(name: String)

    indirect case subclass(name: String, superclass: Class)

    // MARK: - Internal Methods

    func isTypeOf(_ className: String) -> Bool {
        switch self {
        case let .baseClass(name: name):
            return name == className

        case let .subclass(name: name, superclass: superclass):
            return name == className || superclass.isTypeOf(className)
        }
    }

}

extension Class: Decodable {

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let name = try values.decode(String.self, forKey: .name)
        if let superclass = try? values.decode(Class.self, forKey: .superclass) {
            self = .subclass(name: name, superclass: superclass)
        } else {
            self = .baseClass(name: name)
        }
    }

    enum CodingKeys: String, CodingKey {
        case name = "n"
        case superclass = "s"
    }

}

// MARK: -

struct ApplicationState {

    var screens: Screens

    var application: Object

}

extension ApplicationState: Decodable {}

// MARK: -

struct Screens {

    var mainScreen: Object

}

extension Screens: Decodable {}

// MARK: -

struct Object: Equatable {

    var identifier: Int

    var `class`: Class

    var attributes: Dictionary<String, Attribute>

}

extension Object: Decodable {

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try values.decode(Int.self, forKey: .identifier)
        self.class = try values.decode(Class.self, forKey: .class)
        self.attributes = try values.decode(Dictionary<String, Attribute>.self, forKey: .attributes)
    }

    enum CodingKeys: String, CodingKey {
        case identifier = "i"
        case `class` = "c"
        case attributes = "at"
    }

}

// MARK: -

enum Attribute: Equatable {
    case object(Object)
    case array([Object])
    case unknown
}

extension Attribute: Decodable {

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "NSObject":
            let value = try? values.decode(Object.self, forKey: .value)
            if let value = value {
                self = .object(value)
            } else {
                self = .unknown
            }

        case "NSArray":
            let value = try? values.decode(Array<Object>.self, forKey: .value)
            if let value = value {
                self = .array(value)
            } else {
                self = .unknown
            }

        default:
            self = .unknown
        }
    }

    enum CodingKeys: String, CodingKey {
        case type = "t"
        case value = "v"
    }

}
