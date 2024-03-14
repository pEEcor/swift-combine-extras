# Required tools: jq, swift compiler, Xcode

# List xcodes simulators and runtimes with:
# xcrun simctl list

# Variables that are ment to be overridable by specifying them as environment variables when
# calling make
TEST_TARGET ?= CombineExtrasTests
CONFIG ?= debug
TEMP_DIR ?= ${TMPDIR}
PLATFORM ?= macOS

# Fixed variables
PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iPhone)
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,id=$(call udid_for,TV)
PLATFORM_WATCHOS = watchOS Simulator,id=$(call udid_for,Watch)

.PHONY: format test github-test

test:
	@swift test --enable-code-coverage

test-scheme:
ifeq ($(PLATFORM), iOS)
	@echo "Running tests on $(PLATFORM_IOS)"
	set -o pipefail && xcodebuild test \
		-configuration $(CONFIG) \
		-derivedDataPath $(TEMP_DIR)/build \
		-workspace .swiftpm/xcode/package.xcworkspace \
		-scheme $(TEST_TARGET) \
		-destination platform="$(PLATFORM_IOS)" | tee $(TEMP_DIR)/xcodebuild.log
else
	@echo "Running tests on $(PLATFORM_MACOS)"
	set -o pipefail && xcodebuild test \
		-configuration $(CONFIG) \
		-derivedDataPath $(TEMP_DIR)/build \
		-workspace .swiftpm/xcode/package.xcworkspace \
		-scheme $(TEST_TARGET) \
		-destination platform="$(PLATFORM_MACOS)" | tee $(TEMP_DIR)/xcodebuild.log
endif

format:
	swiftformat --config .swiftformat .

define udid_for
$(shell xcrun simctl list --json devices available $(1) | jq -r '.devices | to_entries | map(select(.value | add)) | sort_by(.key) | last.value | last.udid')
endef