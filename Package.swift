// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "Sourcery",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "sourcery", targets: ["sourcery"]),
        .plugin(name: "SourceryCommandPlugin", targets: ["SourceryCommandPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.3"),
        .package(url: "https://github.com/kylef/PathKit.git", exact: "1.0.1"),
        .package(url: "https://github.com/lunij/Stencil.git", branch: "marc/wip"),
        .package(url: "https://github.com/tuist/XcodeProj.git", exact: "8.3.1"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.0.5")),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .executableTarget(name: "sourcery", dependencies: ["SourceryKit"]),
        .target(
            name: "SourceryKit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                "FileSystemEvents",
                "PathKit",
                "Stencil",
                "XcodeProj",
                "Yams"
            ],
            exclude: [
                "Templates"
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "SourceryKitTests",
            dependencies: [
                "SourceryKit"
            ],
            resources: [
                .copy("Fixtures"),
                .copy("Stub/Errors"),
                .copy("Stub/Performance-Code"),
                .copy("Stub/DryRun-Code"),
                .copy("Stub/Result"),
                .copy("Stub/Templates"),
                .copy("Stub/Source")
            ]
        ),
        .target(name: "FileSystemEvents"),
        .testTarget(name: "FileSystemEventsTests", dependencies: ["FileSystemEvents"]),
        .testTarget(
            name: "SystemTests",
            dependencies: [
                "PathKit"
            ],
            resources: [
                .copy("Resources/Context"),
                .copy("Resources/Expected"),
                .copy("Resources/Templates")
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
        ),
        .macro(
            name: "DynamicMemberLookupMacro",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ]
        ),
        .target(
            name: "DynamicMemberLookup",
            dependencies: [
                "DynamicMemberLookupMacro"
            ]
        ),
        .testTarget(
            name: "DynamicMemberLookupMacroTests",
            dependencies: [
                "DynamicMemberLookupMacro",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)
