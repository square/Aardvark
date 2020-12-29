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

protocol NetworkSession {

    func performDataTask(with url: URL, completionHandler: @escaping (Data?) -> Void)

    func performDataTask(with request: URLRequest, completionHandler: @escaping (Data?) -> Void)

}

extension URLSession: NetworkSession {

    func performDataTask(with url: URL, completionHandler: @escaping (Data?) -> Void) {
        let dataTask = self.dataTask(with: url) { data, _, _ in
            completionHandler(data)
        }
        dataTask.resume()
    }

    func performDataTask(with request: URLRequest, completionHandler: @escaping (Data?) -> Void) {
        let dataTask = self.dataTask(with: request) { data, _, _ in
            completionHandler(data)
        }
        dataTask.resume()
    }

}
