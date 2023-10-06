// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "Sourcery",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .executable(name: "sourcery", targets: ["sourcery"]),
        .library(name: "SourceryRuntime", targets: ["SourceryRuntime"]),
        .library(name: "SourcerySwift", targets: ["SourcerySwift"]),
        .plugin(name: "SourceryCommandPlugin", targets: ["SourceryCommandPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.3"),
        .package(url: "https://github.com/kylef/PathKit.git", exact: "1.0.1"),
        .package(url: "https://github.com/lunij/StencilSwiftKit.git", branch: "marc/wip"),
        .package(url: "https://github.com/tuist/XcodeProj.git", exact: "8.3.1"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "508.0.0")
    ],
    targets: [
        .executableTarget(name: "sourcery", dependencies: ["SourceryKit"]),
        .target(
            name: "SourceryKit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                "PathKit",
                "SourceryRuntime",
                "SourcerySwift",
                "SourceryUtils",
                "StencilSwiftKit",
                "XcodeProj",
                "Yams"
            ],
            exclude: [
                "Templates"
            ]
        ),
        .target(name: "SourceryRuntime"),
        .target(name: "SourceryUtils", dependencies: ["PathKit"]),
        .target(
            name: "SourcerySwift",
            dependencies: [
              "PathKit",
              "SourceryRuntime",
              "SourceryUtils"
            ]
        ),
        .testTarget(
            name: "SourceryKitTests",
            dependencies: [
                "SourceryKit"
            ],
            resources: [
                .copy("Stub/Configs"),
                .copy("Stub/Errors"),
                .copy("Stub/SwiftTemplates"),
                .copy("Stub/Performance-Code"),
                .copy("Stub/DryRun-Code"),
                .copy("Stub/Result"),
                .copy("Stub/Templates"),
                .copy("Stub/Source")
            ]
        ),
        .target(
            name: "CodableContext",
            path: "Tests/TemplateTests",
            exclude: [
                "Context/AutoCases.swift",
                "Context/AutoEquatable.swift",
                "Context/AutoHashable.swift",
                "Context/AutoLenses.swift",
                "Context/AutoMockable.swift",
                "Context/LinuxMain.swift",
                "Generated/AutoCases.generated.swift",
                "Generated/AutoEquatable.generated.swift",
                "Generated/AutoHashable.generated.swift",
                "Generated/AutoLenses.generated.swift",
                "Generated/AutoMockable.generated.swift",
                "Generated/LinuxMain.generated.swift",
                "Expected",
                "SystemTests.swift"
            ],
            sources: [
                "Context/AutoCodable.swift",
                "Generated/AutoCodable.generated.swift"
            ]
        ),
        .testTarget(
            name: "TemplateTests",
            dependencies: [
                "CodableContext",
                "PathKit"
            ],
            exclude: [
                "Generated"
            ],
            resources: [
                .copy("Templates"),
                .copy("Context"),
                .copy("Expected")
            ]
        ),
        .plugin(
            name: "SourceryCommandPlugin",
            capability: .command(
                intent: .custom(
                    verb: "sourcery-command",
                    description: "Sourcery command plugin for code generation"
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Need permission to write generated files to package directory")
                ]
            ),
            dependencies: ["sourcery"]
        )
    ]
)
