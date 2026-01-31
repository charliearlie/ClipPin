import Foundation

public struct Preferences: Codable, Equatable {
    public var launchAtLogin: Bool = false
    public var isPaused: Bool = false
    public var pauseAutoResumeMinutes: Int? = 5  // nil = stay paused until manual
    public var sensitiveDataRules: [String: String] = [
        "creditCard": "allow", // changed from askEachTime to allow (warning icon only)
        "apiKey": "allow",
        "password": "autoDelete30s",
        "privateKey": "neverStore"
    ]
    public var maxHistoryItems: Int = 50
    public var maxPinnedItems: Int = 20
    
    public init() {}
}
