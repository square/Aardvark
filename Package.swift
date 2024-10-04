// swift-tools-version:5.10

import PackageDescription

let package = Package(
	name: "Aardvark",
    defaultLocalization: "en",
	platforms: [
		.iOS(.v14),
	],
	products: [
        .library(
            name: "Aardvark",
            targets: ["Aardvark", "AardvarkSwift"]
        ),
        .library(
            name: "AardvarkLoggingUI",
            targets: ["AardvarkLoggingUI"]
        ),
		.library(
			name: "CoreAardvark",
			targets: ["CoreAardvark", "CoreAardvarkSwift"]
		),
	],
	targets: [
        .target(
            name: "Aardvark",
            dependencies: ["CoreAardvark"],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            cSettings: [
                .define("SWIFT_PACKAGE"),
            ]
        ),
        .target(
            name: "AardvarkSwift",
            dependencies: ["Aardvark"],
            cSettings: [
                .define("SWIFT_PACKAGE"),
            ]
        ),
        .target(
            name: "AardvarkLoggingUI",
            dependencies: ["CoreAardvark"],
            cSettings: [
                .define("SWIFT_PACKAGE"),
                .headerSearchPath("private"),
            ]
        ),
		.target(
			name: "CoreAardvark",
            resources: [
                .process("Resources/en.lproj"),
            ],
            cSettings: [
                .define("SWIFT_PACKAGE"),
                .headerSearchPath("private"),
            ]
		),
        .target(
            name: "CoreAardvarkSwift",
            dependencies: ["CoreAardvark"],
            cSettings: [
                .define("SWIFT_PACKAGE"),
            ]
        ),
	]
)
