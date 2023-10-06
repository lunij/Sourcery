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
        .library(name: "SourceryStencil", targets: ["SourceryStencil"]),
        .library(name: "SourcerySwift", targets: ["SourcerySwift"]),
        .library(name: "SourceryFramework", targets: ["SourceryFramework"]),
        .plugin(name: "SourceryCommandPlugin", targets: ["SourceryCommandPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.3"),
        .package(url: "https://github.com/kylef/PathKit.git", exact: "1.0.1"),
        .package(url: "https://github.com/SwiftGen/StencilSwiftKit.git", exact: "2.10.1"),
        .package(url: "https://github.com/tuist/XcodeProj.git", exact: "8.3.1"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "508.0.0")
    ],
    targets: [
        .executableTarget(name: "sourcery", dependencies: ["SourceryLib"]),
        .target(
            name: "SourceryLib",
            dependencies: [
                "SourceryFramework",
                "SourceryRuntime",
                "SourceryStencil",
                "SourcerySwift",
                "PathKit",
                "Yams",
                "StencilSwiftKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                "XcodeProj"
            ],
            exclude: [
                "Templates",
            ]
        ),
        .target(name: "SourceryRuntime"),
        .target(name: "SourceryUtils", dependencies: ["PathKit"]),
        .target(
            name: "SourceryFramework",
            dependencies: [
              "PathKit",
              .product(name: "SwiftSyntax", package: "swift-syntax"),
              .product(name: "SwiftParser", package: "swift-syntax"),
              "SourceryUtils",
              "SourceryRuntime"
            ]
        ),
        .target(
            name: "SourceryStencil",
            dependencies: [
              "PathKit",
              "SourceryRuntime",
              "StencilSwiftKit",
            ]
        ),
        .target(
            name: "SourcerySwift",
            dependencies: [
              "PathKit",
              "SourceryRuntime",
              "SourceryUtils"
            ]
        ),
        .testTarget(
            name: "SourceryLibTests",
            dependencies: [
                "SourceryLib"
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
                "TemplatesTests.swift"
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
