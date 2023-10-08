
format:
	swiftformat .
	swiftlint --fix --strict --no-cache

lint:
	swiftformat . --lint
	swiftlint --strict --no-cache

generate:
	swift run sourcery --config Sources/ContextExamples/.sourcery.yml
	swift run sourcery --config Sources/SourceryRuntime/.sourcery.yml
	Scripts/PackageContent.swift "Sources/SourceryRuntime" > "Sources/SourceryKit/SwiftTemplate/SourceryRuntime.content.generated.swift"
