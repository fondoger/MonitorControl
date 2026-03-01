PROJECT = MonitorControl.xcodeproj
SCHEME = MonitorControl
BUILD_DIR = build

DERIVED_DATA = $(BUILD_DIR)/DerivedData

.PHONY: build-app clean lint format

build-app:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(DERIVED_DATA) \
		build
	rm -rf $(BUILD_DIR)/MonitorControl.app
	cp -R $(DERIVED_DATA)/Build/Products/Release/MonitorControl.app $(BUILD_DIR)/
	@echo ""
	@echo "Built: $(BUILD_DIR)/MonitorControl.app"

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(BUILD_DIR)/DerivedData $(BUILD_DIR)/MonitorControl.app

lint:
	swiftlint

format:
	swiftformat .
