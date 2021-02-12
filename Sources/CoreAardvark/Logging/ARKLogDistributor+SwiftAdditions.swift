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

import Foundation

extension ARKLogDistributor {

    /// Creates a log message and distributes it to the log observers.
    ///
    /// - parameter text: The text of the log message.
    /// - parameter type: The type of log message.
    /// - parameter image: An optional image to be attached to the log message. Typically used for messages of type
    /// `.screenshot`.
    /// - parameter parameters: A set of key/value pairs that is persisted with the log message.
    /// - parameter userInfo: A set of key/value pairs that is _not_ persisted with the log message, but rather can be
    /// used to control how the message is processed by various log observers.
    public func log(
        _ text: String,
        type: ARKLogType = .default,
        image: UIImage? = nil,
        parameters: [String: String] = [:],
        userInfo: [AnyHashable: Any]? = nil
    ) {
        log(withText: text, image: image, type: type, parameters: parameters, userInfo: userInfo)
    }

    /// Creates a log message and distributes it to the log observers.
    ///
    /// - parameter format: The format string for the text of the log message.
    /// - parameter arguments: The arguments to apply to the format string.
    /// - parameter type: The type of log message.
    /// - parameter image: An optional image to be attached to the log message. Typically used for messages of type
    /// `.screenshot`.
    /// - parameter parameters: A set of key/value pairs that is persisted with the log message.
    /// - parameter userInfo: A set of key/value pairs that is _not_ persisted with the log message, but rather can be
    /// used to control how the message is processed by various log observers.
    public func log(
        format: String,
        _ arguments: CVarArg...,
        type: ARKLogType = .default,
        image: UIImage? = nil,
        parameters: [String: String] = [:],
        userInfo: [AnyHashable: Any]? = nil
    ) {
        let text = String(format: format, arguments: arguments)
        log(text, type: type, image: image, parameters: parameters, userInfo: userInfo)
    }

}
