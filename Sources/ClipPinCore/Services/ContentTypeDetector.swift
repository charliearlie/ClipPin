import Foundation

class ContentTypeDetector {
    static let shared = ContentTypeDetector()
    
    private init() {}
    
    func detect(content: String) -> ContentType {
        if isURL(content) { return .url }
        if isEmail(content) { return .email }
        if isPhone(content) { return .phone }
        if isJSON(content) { return .json }
        if isColorHex(content) { return .colorHex }
        return .plain
    }
    
    private func isURL(_ content: String) -> Bool {
        // Simple heuristic: starts with http:// or https://
        return content.lowercased().hasPrefix("http://") || content.lowercased().hasPrefix("https://")
    }
    
    private func isEmail(_ content: String) -> Bool {
        // Basic regex for email
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: content)
    }
    
    private func isPhone(_ content: String) -> Bool {
        // Basic phone number heuristic: mostly digits, maybe some symbols, between 7-15 length
        let digits = content.filter { $0.isNumber }
        let validLength = digits.count >= 7 && digits.count <= 15
        
        // If content contains letters, it's not strictly a phone number usually (unless vanity)
        let hasLetters = content.contains { $0.isLetter }
        if hasLetters { return false }
        
        // Content should look like phone: digits, spaces, -, +, (, )
        let allowed = CharacterSet(charactersIn: "0123456789 +-()")
        let contentSet = CharacterSet(charactersIn: content)
        
        return validLength && allowed.isSuperset(of: contentSet)
    }
    
    private func isJSON(_ content: String) -> Bool {
        guard content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") || content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") else { return false }
        guard let data = content.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) != nil
    }
    
    private func isColorHex(_ content: String) -> Bool {
        let regex = "^#[0-9A-Fa-f]{6}$"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        return predicate.evaluate(with: content)
    }
}
