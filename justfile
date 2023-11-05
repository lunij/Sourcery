
format:
	swiftformat .
	swiftlint --fix --strict --no-cache

lint:
	swiftformat . --lint
	swiftlint --strict --no-cache

generate:
	swift run sourcery
