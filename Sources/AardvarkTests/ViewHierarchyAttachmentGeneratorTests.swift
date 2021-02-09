//
//  Copyright © 2021 Square, Inc.
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

@testable import Aardvark

final class ViewHierarchyAttachmentGeneratorTests: XCTestCase {

    func testAttachmentMetadata() {
        let attachment = ViewHierarchyAttachmentGenerator.generateAttachment(for: [])

        XCTAssertEqual(attachment.fileName, "view_hierarchy.txt")
        XCTAssertEqual(attachment.dataMIMEType, "text/plain")
    }

    func testDescriptionForSimpleWindow() {
        let window = TestWindow()
        let attachment = ViewHierarchyAttachmentGenerator.generateAttachment(for: [window])
        let description = String(data: attachment.data, encoding: .utf8)

        XCTAssertEqual(
            description,
            """
            Window Description

            """
        )
    }

    func testDescriptionForWindowWithSubviews() {
        let window = TestWindow()

        let firstSubview = TestView(identifier: "B")
        window.addSubview(firstSubview)
        firstSubview.addSubview(TestView(identifier: "C"))

        window.addSubview(TestView(identifier: "A"))

        let attachment = ViewHierarchyAttachmentGenerator.generateAttachment(for: [window])
        let description = String(data: attachment.data, encoding: .utf8)

        XCTAssertEqual(
            description,
            """
            Window Description
               | View Description for B
               |    | View Description for C
               | View Description for A

            """
        )
    }

    func testDescriptionForWindowWithSublayers() {
        let window = TestWindow()

        let subview = TestView(identifier: "Subview")
        window.addSubview(subview)

        subview.layer.addSublayer(TestLayer())
        subview.layer.addSublayer(TestLayer())

        let attachment = ViewHierarchyAttachmentGenerator.generateAttachment(for: [window])
        let description = String(data: attachment.data, encoding: .utf8)

        XCTAssertEqual(
            description,
            """
            Window Description
               | View Description for Subview
               |    | Layer Description
               |    | Layer Description

            """
        )
    }

    func testDescriptionForWindowWithViewController() {
        let window = TestWindow()

        let viewController = TestViewController()
        window.rootViewController = viewController
        window.addSubview(viewController.view)

        let attachment = ViewHierarchyAttachmentGenerator.generateAttachment(for: [window])
        let description = String(data: attachment.data, encoding: .utf8)

        XCTAssertEqual(
            description,
            """
            Window Description
               | VC: View Controller Description
               | View Description for Managed View

            """
        )
    }

}

// MARK: -

private final class TestWindow: UIWindow {

    override var description: String {
        return "Window Description"
    }

}

private final class TestView: UIView {

    // MARK: - Life Cycle

    init(identifier: String) {
        self.identifier = identifier

        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let identifier: String

    // MARK: - UIView

    override var description: String {
        "View Description for \(identifier)"
    }

}

private final class TestLayer: CALayer {

    override var description: String {
        "Layer Description"
    }

}

private final class TestViewController: UIViewController {

    override func loadView() {
        view = TestView(identifier: "Managed View")
    }

    override var description: String {
        "View Controller Description"
    }

}
