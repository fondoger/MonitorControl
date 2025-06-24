
//  Copyright © MonitorControl. @JoniVR, @theOneyouseek, @waydabber and others

import Foundation
import AppKit

class Theme {
    static let shared = Theme()

    private let skyLightPath = "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"
    private var skyLightHandle: UnsafeMutableRawPointer?
    private var SLSSetAppearanceThemeLegacy: (@convention(c) (Bool) -> Void)?
    private var SLSGetAppearanceThemeLegacy: (@convention(c) () -> Bool)?

    init() {
        skyLightHandle = dlopen(skyLightPath, RTLD_LAZY)
        if let handle = skyLightHandle {
            SLSSetAppearanceThemeLegacy = unsafeBitCast(dlsym(handle, "SLSSetAppearanceThemeLegacy"), to: (@convention(c) (Bool) -> Void)?.self)
            SLSGetAppearanceThemeLegacy = unsafeBitCast(dlsym(handle, "SLSGetAppearanceThemeLegacy"), to: (@convention(c) () -> Bool)?.self)
        }
    }

    var isDarkMode: Bool {
        get {
            return SLSGetAppearanceThemeLegacy?() ?? false
        }
        set {
            SLSSetAppearanceThemeLegacy?(newValue)
        }
    }

    func toggle() {
        isDarkMode.toggle()
    }

    deinit {
        if let handle = skyLightHandle {
            dlclose(handle)
        }
    }
}
