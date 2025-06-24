
import Foundation

class NightShift {
    static let shared = NightShift()
    
    private let coreBrightnessPath = "/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness"
    private var coreBrightnessHandle: UnsafeMutableRawPointer?
    private var client: AnyObject?
    
    init() {
        coreBrightnessHandle = dlopen(coreBrightnessPath, RTLD_LAZY)
        guard let _ = coreBrightnessHandle else { return }
        
        // Get the CBBlueLightClient class and create an instance
        guard let CBBlueLightClient = NSClassFromString("CBBlueLightClient") as? NSObject.Type else { return }
        // self.client = CBBlueLightClient.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue().perform(NSSelectorFromString("init"))?.takeUnretainedValue()
        self.client = CBBlueLightClient.init()
    }
    
    var isEnabled: Bool {
        get {
            guard let client = self.client else { return false }
            
            var status = (
                active: false,
                enabled: false,
                sunSchedulePermitted: false,
                mode: Int32(0),
                schedule: (fromTime: (hour: Int32(0), minute: Int32(0)), toTime: (hour: Int32(0), minute: Int32(0))),
                disableFlags: UInt64(0),
                available: false
            )
            
            let selector = Selector("getBlueLightStatus:")
            let method = class_getInstanceMethod(type(of: client), selector)
            if let method = method {
                typealias GetStatusFunction = @convention(c) (AnyObject, Selector, UnsafeMutableRawPointer) -> Bool
                let implementation = method_getImplementation(method)
                let function = unsafeBitCast(implementation, to: GetStatusFunction.self)
                
                withUnsafeMutablePointer(to: &status) { ptr in
                    _ = function(client, selector, ptr)
                }
            }
            
            return status.enabled
        }
        set {
            guard let client = self.client else { return }
            
            let selector = Selector("setEnabled:")
            let method = class_getInstanceMethod(type(of: client), selector)
            if let method = method {
                typealias SetEnabledFunction = @convention(c) (AnyObject, Selector, Bool) -> Bool
                let implementation = method_getImplementation(method)
                let function = unsafeBitCast(implementation, to: SetEnabledFunction.self)
                _ = function(client, selector, newValue)
            }
        }
    }
    
    var strength: Float {
        get {
            guard let client = self.client else { return 0.0 }
            
            var strength: Float = 0.0
            let selector = Selector("getStrength:")
            let method = class_getInstanceMethod(type(of: client), selector)
            if let method = method {
                typealias GetStrengthFunction = @convention(c) (AnyObject, Selector, UnsafeMutablePointer<Float>) -> Bool
                let implementation = method_getImplementation(method)
                let function = unsafeBitCast(implementation, to: GetStrengthFunction.self)
                
                withUnsafeMutablePointer(to: &strength) { ptr in
                    _ = function(client, selector, ptr)
                }
            }
            return strength
        }
        set {
            guard let client = self.client else { return }
            
            let selector = Selector("setStrength:commit:")
            let method = class_getInstanceMethod(type(of: client), selector)
            if let method = method {
                typealias SetStrengthFunction = @convention(c) (AnyObject, Selector, Float, Bool) -> Bool
                let implementation = method_getImplementation(method)
                let function = unsafeBitCast(implementation, to: SetStrengthFunction.self)
                _ = function(client, selector, newValue, true)
            }
        }
    }
    
    func toggle() {
        isEnabled.toggle()
    }
    
    deinit {
        if let handle = coreBrightnessHandle {
            dlclose(handle)
        }
    }
}
