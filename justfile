
format:
	swiftformat .
	swiftlint --fix --strict --no-cache

lint:
	swiftformat . --lint
	swiftlint --strict --no-cache

generate:
	Scripts/PackageContent.swift "Sources/SourceryRuntime" > "Sources/SourceryKit/SwiftTemplate/SourceryRuntime.content.generated.swift"
	swift run sourcery
