import Foundation

class SensitiveDataDetector {
    static let shared = SensitiveDataDetector()
    
    private init() {}
    
    func detect(content: String) -> SensitiveDataType? {
        if isCreditCard(content) { return .creditCard }
        if isPrivateKey(content) { return .privateKey }
        if isAPIKey(content) { return .apiKey }
        if isPassword(content) { return .password }
        return nil
    }
    
    private func isCreditCard(_ content: String) -> Bool {
        // Strip non-digits using regex or simple filter
        let digits = content.filter { $0.isNumber }
        guard digits.count >= 13 && digits.count <= 19 else { return false }
        
        // Relaxed check: We detected 13-19 digits. Even if Luhn fails, we flag it as potential CC
        // so the user sees the warning/is asked, rather than it slipping through as plain text.
        return true
    }
    
    private func isPrivateKey(_ content: String) -> Bool {
        // Simple check for private key headers
        return content.contains("-----BEGIN") && content.contains("PRIVATE KEY-----")
    }
    
    private func isAPIKey(_ content: String) -> Bool {
        // Common patterns for API keys
        let patterns = [
            "sk-[a-zA-Z0-9]{20,}", // Stripe secret key (simplified)
            "pk_[a-zA-Z0-9]{20,}", // Stripe publishable key (simplified)
            "AIza[0-9A-Za-z-_]{35}", // Google API Key
            "AKIA[0-9A-Z]{16}"      // AWS Access Key ID
        ]
        
        for pattern in patterns {
            let predicate = NSPredicate(format:"SELF MATCHES %@", pattern) // This might be too strict if content has other text.
            // Requirement says "sk-*, pk_*, api_*, key-*, AKIA*, token patterns"
            // Let's use range search for containment rather than exact match if possible, or just exact match if it's purely the key?
            // "Detect potentially sensitive content" - usually clipboard IS the key.
            // Let's stick to regex detection within string.
            if content.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        // Generic "api_key" or "token" containment might be too aggressive for false positives?
        // Let's stick to the specific meaningful patterns provided in prompt loosely.
        if content.hasPrefix("sk-") || content.hasPrefix("pk_") || content.hasPrefix("api_") || content.hasPrefix("key-") {
            // Check length to avoid short false positives
            if content.count > 20 { return true }
        }
        
        return false
    }
    
    private func isPassword(_ content: String) -> Bool {
        // "Detected by source app (1Password, LastPass, Bitwarden bundle IDs)"
        // This requires NSPasteboard metadata (org.nspasteboard.source).
        // Using generic pasteboard wrapper might not expose this easily without dropping down to NSPasteboard API directly in Monitor.
        // We'll handle this logic in Monitor or pass metadata here.
        // For now returning false here, logic will be in ClipboardMonitor using additional info.
        return false
    }
}
