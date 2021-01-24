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

// The objects in this file are representations of the JSON structure as defined by the `.reveal` file format. The
// coding keys for each object line up with the keys used in that JSON.

/// Representation of a class type in the Reveal JSON format of the application state.
enum Class: Equatable {

    /// A class which has no superclass, i.e. `NSObject`.
    case baseClass(name: String)

    /// A class that inherits from another class.
    indirect case subclass(name: String, superclass: Class)

    // MARK: - Internal Methods

    /// Returns a boolean indicating whether the class is, or inherits from, a class of the given `className`.
    func isTypeOf(_ className: String) -> Bool {
        switch self {
        case let .baseClass(name: name):
            return name == className

        case let .subclass(name: name, superclass: superclass):
            return name == className || superclass.isTypeOf(className)
        }
    }

}

extension Class: Codable {

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let name = try values.decode(String.self, forKey: .name)
        if let superclass = try? values.decode(Class.self, forKey: .superclass) {
            self = .subclass(name: name, superclass: superclass)
        } else {
            self = .baseClass(name: name)
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .baseClass(name: name):
            try values.encode(name, forKey: .name)
        case let .subclass(name: name, superclass: superclass):
            try values.encode(name, forKey: .name)
            try values.encode(superclass, forKey: .superclass)
        }
    }

    enum CodingKeys: String, CodingKey {
        case name = "n"
        case superclass = "s"
    }

}

// MARK: -

/// Representation of the application state used as the top level object in the Reveal JSON format.
///
/// This is only a subset of the fields available in the complete JSON. We don't require any of the other fields for the
/// processing done in generating the bug report, so they are omitted here to avoid unnecessary parsing.
struct ApplicationState {

    /// A container holding objects representing each `UIScreen` instance available to the application.
    var screens: Screens

    /// A representation of the application's `UIApplication` instance.
    var application: Object

}

extension ApplicationState: Codable {}

// MARK: -

/// Representation of all screens available to the application used in the Reveal JSON format of the application state.
///
/// This is only a subset of the fields available in the complete JSON. We don't require any of the other fields for the
/// processing done in generating the bug report, so they are omitted here to avoid unnecessary parsing.
struct Screens {

    /// An object representing the application's main screen (`UIScreen.main`).
    var mainScreen: Object

}

extension Screens: Codable {}

// MARK: -

/// Representation of an object in the Reveal JSON format of the application state.
///
/// This is only a subset of the fields available in the complete JSON. We don't require any of the other fields for the
/// processing done in generating the bug report, so they are omitted here to avoid unnecessary parsing.
struct Object: Equatable {

    /// Unique identifier corresponding to this object in the application state snapshot.
    var identifier: Int

    /// Representation of the object's class type.
    var `class`: Class

    /// Dictionary containing all of the object's attributes, keyed off of the property name.
    var attributes: Dictionary<String, Attribute>

}

extension Object: Codable {

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try values.decode(Int.self, forKey: .identifier)
        self.class = try values.decode(Class.self, forKey: .class)
        self.attributes = try values.decode(Dictionary<String, Attribute>.self, forKey: .attributes)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(identifier, forKey: .identifier)
        try values.encode(`class`, forKey: .class)
        try values.encode(attributes, forKey: .attributes)
    }

    enum CodingKeys: String, CodingKey {
        case identifier = "i"
        case `class` = "c"
        case attributes = "at"
    }

}

// MARK: -

/// Representation of an object's attribute used by the Reveal JSON format of the application state.
enum Attribute: Equatable {

    /// Attribute that represents a single object.
    case object(Object)

    /// Attribute that represents an array of objects.
    case array([Object])

    /// Attribute of a type that could not be parsed. Since we only parse the application state here to find objects
    /// that can be snapshotted, we can generally ignore these unknown attributes.
    case unknown

}

extension Attribute: Codable {

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

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .unknown:
            try values.encode("NSObject", forKey: .type)

        case let .array(contents):
            try values.encode("NSArray", forKey: .type)
            try values.encode(contents, forKey: .value)

        case let .object(object):
            try values.encode("NSObject", forKey: .type)
            try values.encode(object, forKey: .value)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type = "t"
        case value = "v"
    }

}
