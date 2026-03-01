# AGENTS.md — MonitorControl

## Project Overview

MonitorControl is a macOS menu bar utility (AppKit, Swift 5.5) that controls external
display brightness, contrast, and volume via DDC protocol and native Apple APIs. It has
two Xcode targets: `MonitorControl` (main app) and `MonitorControlHelper` (login item).
Dependencies are managed via Swift Package Manager integrated into Xcode.

## Build Commands

```sh
# Build (Debug)
xcodebuild -project MonitorControl.xcodeproj -scheme MonitorControl -configuration Debug build

# Build (Release)
xcodebuild -project MonitorControl.xcodeproj -scheme MonitorControl -configuration Release build

# Clean build
xcodebuild -project MonitorControl.xcodeproj -scheme MonitorControl clean build
```

There is no standalone `Package.swift`. Open `MonitorControl.xcodeproj` in Xcode and
resolve packages via File > Packages > Resolve Package Versions if SPM dependencies
fail to download automatically.

## Linting & Formatting

SwiftLint and SwiftFormat run automatically as Xcode build phase scripts. They can also
be run manually:

```sh
# Lint
swiftlint

# Format (applies to entire repo)
swiftformat .
```

Install via Homebrew if missing: `brew install swiftlint swiftformat`

Key SwiftLint rules (`.swiftlint.yml`):
- `line_length` — disabled (long lines are acceptable)
- `function_body_length` — disabled
- `identifier_name` — disabled
- `trailing_comma` — disabled (trailing commas are used)
- `large_tuple` — disabled
- `type_body_length` — max 500 lines
- `file_length` — max 750 lines
- `cyclomatic_complexity` — ignores case statements
- `opening_brace` — allows multiline function signatures

Key SwiftFormat rules (`.swiftformat`):
- 2-space indentation
- No spaces around operators (`--nospaceoperators`)
- Explicit `self` — always insert (`--self insert`)
- Lowercase exponent case

## Testing

There are no tests in this project. No test targets, no XCTest files, no test framework.

## Code Style Guidelines

### Indentation & Formatting
- **2-space indentation** throughout (enforced by SwiftFormat).
- K&R brace style (opening brace on same line as declaration).
- No strict line length limit — long lines are common and accepted.
- Trailing commas in multi-line collections and argument lists.
- Single blank line between methods. No blank lines after opening braces or before
  closing braces.

### Imports
- Sorted alphabetically, no blank-line separation between system and third-party imports.
- Common imports: `Cocoa`, `Foundation`, `os.log`, `IOKit`.

```swift
import AVFoundation
import Cocoa
import Foundation
import MediaKeyTap
import os.log
import Settings
```

### Self Usage
- **Always use explicit `self`** for instance property and method access, even when not
  required by the compiler. This is enforced by SwiftFormat (`--self insert`).

```swift
self.subscribeEventListeners()
self.savePref(value, for: .brightness)
self.smoothBrightnessTransient = value
```

### Naming Conventions
- **Types** (classes, enums, structs): `UpperCamelCase` — `Display`, `OtherDisplay`,
  `DisplayManager`, `MediaKeyTapManager`.
- **Enum cases**: `lowerCamelCase` — `case brightness`, `case audioSpeakerVolume`.
- **Variables/properties**: `lowerCamelCase` — `smoothBrightnessTransient`,
  `defaultGammaTableRed`. Abbreviations stay lowercase in camelCase: `ddc`, `arm64ddc`.
- **Boolean properties**: often use `is` prefix (`isVirtual`, `isDummy`) but not always
  (`enableMuteUnmute`, `hideOsd`).
- **Top-level debug/config constants**: `UPPER_SNAKE_CASE` — `DEBUG_SW`,
  `DDC_MAX_DETECT_LIMIT`.
- **Global variables**: `lowerCamelCase` — `app`, `menu`, `prefs`.
- **Unused parameters**: replaced with `_` — `func applicationDidFinishLaunching(_: Notification)`.

### Access Control
- Most declarations use implicit `internal` access (no modifier).
- `private` is used selectively for implementation-detail methods.
- `public` is used on extensions of system types and some key APIs.
- `fileprivate` is never used.

### Error Handling
- **`guard` with early return** is the primary pattern — used extensively for
  preconditions and nil checks.
- `do/catch` is rare, used only for serialization and audio player initialization.
- `Result` type is never used.
- Optional chaining and nil-coalescing (`??`) are used heavily.
- `if let` is used for optional binding and type downcasting.

```swift
guard !self.isDummy else {
  return
}
guard CGGetOnlineDisplayList(16, &onlineDisplayIDs, &displayCount) == .success else {
  os_log("Unable to get display list.", type: .info)
  return
}
```

### Logging
- Use `os_log` from `os.log` exclusively. Never use `print()` or `NSLog`.

```swift
os_log("Display init with prefsIdentifier %{public}@", type: .info, self.prefsId)
```

### Protocol Conformance
- All protocol conformances are listed on the class declaration line, comma-separated.
  Protocol conformance is NOT split into separate extensions.

```swift
class AppDelegate: NSObject, NSApplicationDelegate { ... }
class DisplaysPrefsViewController: NSViewController, SettingsPane, NSTableViewDataSource, NSTableViewDelegate { ... }
```

### Extensions
- Extensions on system/Apple types go in `Extensions/` with naming pattern
  `TypeName+Extension.swift`.
- Extensions are used to add functionality to external types only, not to organize the
  class's own code.

### Singletons
- Use `static let shared` pattern:

```swift
public static let shared = DisplayManager()
```

### Patterns & Architecture
- **No Swift Concurrency** (`async`/`await`) — uses GCD (`DispatchQueue`,
  `DispatchSemaphore`, `asyncAfter`).
- **No Combine, no SwiftUI** — pure AppKit with storyboards.
- **Manual app lifecycle** — `main.swift` with explicit `NSApplication.shared.run()`,
  no `@main` or `@NSApplicationMain`.
- **Global state** — `app`, `menu`, `prefs` are module-level globals in `main.swift`,
  accessed directly throughout the codebase.
- **Preferences** — all go through global `prefs` (`UserDefaults.standard`) with
  `PrefKey` enum raw values: `prefs.bool(forKey: PrefKey.someKey.rawValue)`.
- **Display-specific prefs** use helper methods that concatenate key + command + display ID.
- **`@objc`** on methods used as selectors or notification handlers.
- **`#available` checks** paired with `DEBUG_MACOS10` flag for macOS version fallbacks.
- **Nested classes** are used for helper/inner types (e.g., `MCSlider` inside `SliderHandler`).
- **Models are classes** (reference semantics), not structs.

### File Headers
- Minimal single-line copyright comment at the top of each file:

```swift
//  Copyright © MonitorControl. @JoniVR, @theOneyouseek, @waydabber and others
```

### Comments
- Use `//` exclusively. No `///` doc comments exist in the codebase.
- Comments explain "why" or edge cases, not "what".

## Project Structure

```
MonitorControl/
├── Enums/              # PrefKey, Command enums
├── Extensions/         # Extensions on system types (CGDirectDisplayID, NSScreen, etc.)
├── Model/              # Display, OtherDisplay, AppleDisplay
├── Support/            # AppDelegate, DisplayManager, DDC, MediaKeyTap, MenuHandler, etc.
├── UI/                 # Storyboards and localization strings (19 languages)
├── View Controllers/   # Preferences panes and onboarding
└── main.swift          # App entry point, global variables, debug flags
MonitorControlHelper/   # Login item helper target
```

## Dependencies (SPM)

- `KeyboardShortcuts` — global keyboard shortcut handling
- `MediaKeyTap` — media key interception (forked at MonitorControl/MediaKeyTap)
- `Settings` — preferences window framework (sindresorhus)
- `SimplyCoreAudio` — audio device monitoring
- `Sparkle` — auto-update framework
- `swift-atomics` — atomic operations

## Deployment

- **Minimum macOS**: 10.15 (Catalina)
- **Hardened Runtime**: Enabled
- **Private Frameworks**: OSD.framework, CoreDisplay.framework, DisplayServices.framework
- **Bridging Header**: `MonitorControl/Support/Bridging-Header.h` (bridges private C APIs)
