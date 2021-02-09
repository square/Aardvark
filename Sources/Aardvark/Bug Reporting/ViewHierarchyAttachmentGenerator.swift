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

@objc(ARKViewHierarchyAttachmentGenerator)
public final class ViewHierarchyAttachmentGenerator: NSObject {

    // MARK: - Public Static Methods

    /// Captures a textual representation of the current view hierarchy and returns a bug report attachment containing
    /// plain text data for that representation.
    @objc
    public static func captureCurrentHierarchy() -> ARKBugReportAttachment {
        generateAttachment(for: UIApplication.shared.windows)
    }

    // MARK: - Internal Static Methods

    internal static func generateAttachment(for windows: [UIWindow]) -> ARKBugReportAttachment {
        var hierarchyDescription = ""
        for window in windows {
            var viewControllerMap: [UIView: UIViewController] = [:]
            window.rootViewController?.appendRecursiveViewControllerMapping(to: &viewControllerMap)

            window.appendRecursiveViewHierarchyDescription(
                to: &hierarchyDescription,
                indentationLevel: 0,
                viewControllerMap: viewControllerMap
            )
        }

        let fileBaseName = NSLocalizedString("view_hierarchy", comment: "File name for view hierarchy attachment")
        let fileName = (fileBaseName as NSString).appendingPathExtension("txt") ?? fileBaseName

        return ARKBugReportAttachment(
            fileName: fileName,
            data: hierarchyDescription.data(using: .utf8)!,
            dataMIMEType: "text/plain"
        )
    }

}

// MARK: -

extension UIViewController {

    fileprivate func appendRecursiveViewControllerMapping(to map: inout [UIView: UIViewController]) {
        if isViewLoaded {
            map[view] = self
        }

        for child in children {
            child.appendRecursiveViewControllerMapping(to: &map)
        }
    }

}

// MARK: -

extension UIView {

    fileprivate func appendRecursiveViewHierarchyDescription(
        to description: inout String,
        indentationLevel: Int,
        viewControllerMap: [UIView: UIViewController]
    ) {
        if let viewController = viewControllerMap[self] {
            description.append(String(repeating: "   | ", count: indentationLevel))
            description.append("VC: \(viewController)\n")
        }

        description.append(String(repeating: "   | ", count: indentationLevel))
        description.append("\(self)\n")

        for subview in subviews {
            subview.appendRecursiveViewHierarchyDescription(
                to: &description,
                indentationLevel: indentationLevel + 1,
                viewControllerMap: viewControllerMap
            )
        }

        // Each subview's layer is also a sublayer, but we should only include it in the hierarchy once (with the
        // subview).
        let sublayersToSkip = Set(subviews.map { $0.layer })

        for sublayer in (layer.sublayers ?? []) {
            if sublayersToSkip.contains(sublayer) {
                continue
            }

            sublayer.appendRecursiveLayerHierarchyDescription(to: &description, indentationLevel: indentationLevel + 1)
        }
    }

}

// MARK: -

extension CALayer {

    fileprivate func appendRecursiveLayerHierarchyDescription(
        to description: inout String,
        indentationLevel: Int
    ) {
        description.append(String(repeating: "   | ", count: indentationLevel))
        description.append("\(self)\n")

        for sublayer in (sublayers ?? []) {
            sublayer.appendRecursiveLayerHierarchyDescription(to: &description, indentationLevel: indentationLevel + 1)
        }
    }

}
