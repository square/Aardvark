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
			name: "CoreAardvark",
			targets: ["CoreAardvark", "CoreAardvarkSwift"]
		),
	],
	targets: [
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
