# PencilMark — build without Xcode (Command Line Tools are enough).

BUNDLE_ID  := com.aditya.pencilmark
APP_NAME   := PencilMark

# macOS ties the Accessibility grant to the code signature. An ad-hoc signature changes on every
# rebuild, so the permission silently stops applying and has to be re-granted each time. Sign with
# a real identity when the keychain has one — its designated requirement is stable across rebuilds.
# Override with `make app SIGN_ID=<hash-or-name>`, or SIGN_ID=- to force ad-hoc.
SIGN_ID ?= $(shell security find-identity -v -p codesigning 2>/dev/null | awk '$$2 ~ /^[0-9A-F]{40}$$/ {print $$2; exit}')
ifeq ($(strip $(SIGN_ID)),)
SIGN_ID := -
endif
BUILD_DIR  := build
APP        := $(BUILD_DIR)/$(APP_NAME).app
CONFIG     := release

# `make app UNIVERSAL=1` builds a fat arm64 + x86_64 binary.
ifdef UNIVERSAL
  ARCH_FLAGS := --arch arm64 --arch x86_64
  BIN        := .build/apple/Products/Release/$(APP_NAME)
else
  ARCH_FLAGS :=
  BIN        := $(shell swift build -c $(CONFIG) --product $(APP_NAME) --show-bin-path)/$(APP_NAME)
endif

.PHONY: all test build app install run stop clean

all: app

## Run the test suite (a plain executable: XCTest ships only with Xcode).
test:
	@swift run PencilMarkCoreTests

## Compile the executable. `--product` keeps the test runner (which needs a debug,
## testing-enabled build of PencilMarkCore) out of the release build.
build:
	@swift build -c $(CONFIG) $(ARCH_FLAGS) --product $(APP_NAME)

## Assemble and ad-hoc sign the .app bundle.
app: build
	@rm -rf "$(APP)"
	@mkdir -p "$(APP)/Contents/MacOS" "$(APP)/Contents/Resources"
	@cp "$(BIN)" "$(APP)/Contents/MacOS/$(APP_NAME)"
	@cp Info.plist "$(APP)/Contents/Info.plist"
	@[ -d Resources ] && cp -R Resources/. "$(APP)/Contents/Resources/" 2>/dev/null || true
	@codesign --force --sign $(SIGN_ID) --identifier $(BUNDLE_ID) "$(APP)" 2>&1 | sed "s/^/  /"
	@[ -f ../../tools/logo.txt ] && cat ../../tools/logo.txt || true
	@echo "Built $(APP)  (signed with: $(SIGN_ID))"

## Copy to /Applications. Keeping a stable path helps macOS remember the Accessibility grant.
install: app
	@rm -rf "/Applications/$(APP_NAME).app"
	@cp -R "$(APP)" /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

## Launch it. Always runs the /Applications copy: macOS keys the Accessibility grant to
## the app's path, so running a second copy out of build/ would need its own grant.
run: install
	@pkill -x $(APP_NAME) 2>/dev/null || true
	@open "/Applications/$(APP_NAME).app"
	@echo "Running — look for the ✨ icon in the menu bar."

stop:
	@pkill -x $(APP_NAME) 2>/dev/null || true

clean:
	@rm -rf .build "$(BUILD_DIR)"
