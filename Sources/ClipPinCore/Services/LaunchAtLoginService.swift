import Foundation
import ServiceManagement

class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()
    
    private init() {}
    
    var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                // Fallback for older macOS (simplified for MVP, or just return false/true based on simplified check)
                // For MVP without external dependencies, implementing LSSharedFileList accurately is verbose.
                // We'll trust the preference mirroring the state or try a simple check if possible.
                return false // Placeholder for < 13.0
            }
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Failed to update launch at login: \(error)")
                }
            } else {
                // Fallback implementation would go here
                print("Launch at login requires macOS 13+ for this MVP implementation")
            }
        }
    }
}
