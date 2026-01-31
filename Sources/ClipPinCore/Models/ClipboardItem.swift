import Foundation
import CommonCrypto
import CryptoKit

public enum ClipboardItemType: String, Codable {
    case text
    case image
}

public struct ImageMetadata: Codable, Equatable {
    public let width: Int
    public let height: Int
    public let format: String
    public let fileSize: Int
    public let filename: String
    public let thumbnailFilename: String
    
    public init(width: Int, height: Int, format: String, fileSize: Int, filename: String, thumbnailFilename: String) {
        self.width = width
        self.height = height
        self.format = format
        self.fileSize = fileSize
        self.filename = filename
        self.thumbnailFilename = thumbnailFilename
    }
    
    public var dimensionsLabel: String {
        "\(width)×\(height)"
    }
    
    public var sizeLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
}

public enum SensitiveDataType: String, Codable, CaseIterable {
    case creditCard
    case apiKey
    case password
    case privateKey
}

public enum ContentType: String, Codable {
    case url, email, phone, json, colorHex, plain
}

public struct ClipboardItem: Codable, Identifiable, Equatable {
    public let id: UUID
    public var type: ClipboardItemType = .text
    public var timestamp: Date
    public var isPinned: Bool
    public var pinOrder: Int?
    public var copyCount: Int = 1
    
    // Text-specific
    public var content: String?
    public var contentHash: String?
    public var contentType: ContentType?
    public var sensitiveType: SensitiveDataType?
    public var autoDeleteAt: Date?
    public var pinSuggestionDismissed: Bool = false
    
    // Image-specific
    public var imageMetadata: ImageMetadata?
    
    public var displayLabel: String {
        switch type {
        case .text:
            guard let content = content else { return "" }
            if content.count > 50 {
                return String(content.prefix(50)) + "..."
            }
            return content
        case .image:
            return imageMetadata?.dimensionsLabel ?? "Image"
        }
    }
    
    // Init for Text
    public init(id: UUID = UUID(), 
                content: String, 
                timestamp: Date = Date(), 
                isPinned: Bool = false, 
                pinOrder: Int? = nil, 
                copyCount: Int = 1, 
                contentType: ContentType = .plain, 
                sensitiveType: SensitiveDataType? = nil, 
                autoDeleteAt: Date? = nil, 
                pinSuggestionDismissed: Bool = false) {
        self.id = id
        self.type = .text
        self.content = content
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.pinOrder = pinOrder
        
        let data = content.data(using: .utf8) ?? Data()
        self.contentHash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        
        self.copyCount = copyCount
        self.contentType = contentType
        self.sensitiveType = sensitiveType
        self.autoDeleteAt = autoDeleteAt
        self.pinSuggestionDismissed = pinSuggestionDismissed
    }
    
    // Init for Image
    public init(id: UUID = UUID(),
                type: ClipboardItemType = .image,
                imageMetadata: ImageMetadata,
                timestamp: Date = Date(),
                isPinned: Bool = false,
                pinOrder: Int? = nil,
                copyCount: Int = 1) {
        self.id = id
        self.type = type
        self.imageMetadata = imageMetadata
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.pinOrder = pinOrder
        self.copyCount = copyCount
        self.contentType = nil
    }
    
    // Custom encoding/decoding for migration
    enum CodingKeys: String, CodingKey {
        case id, type, content, contentHash, timestamp, isPinned, pinOrder
        case copyCount, contentType, sensitiveType, autoDeleteAt, pinSuggestionDismissed
        case imageMetadata
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        // Default to .text if type is missing (Migration)
        type = try container.decodeIfPresent(ClipboardItemType.self, forKey: .type) ?? .text
        
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        pinOrder = try container.decodeIfPresent(Int.self, forKey: .pinOrder)
        copyCount = try container.decodeIfPresent(Int.self, forKey: .copyCount) ?? 1
        
        // Text fields
        content = try container.decodeIfPresent(String.self, forKey: .content)
        contentHash = try container.decodeIfPresent(String.self, forKey: .contentHash)
        contentType = try container.decodeIfPresent(ContentType.self, forKey: .contentType)
        sensitiveType = try container.decodeIfPresent(SensitiveDataType.self, forKey: .sensitiveType)
        autoDeleteAt = try container.decodeIfPresent(Date.self, forKey: .autoDeleteAt)
        pinSuggestionDismissed = try container.decodeIfPresent(Bool.self, forKey: .pinSuggestionDismissed) ?? false
        
        // Image fields
        imageMetadata = try container.decodeIfPresent(ImageMetadata.self, forKey: .imageMetadata)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encodeIfPresent(pinOrder, forKey: .pinOrder)
        try container.encode(copyCount, forKey: .copyCount)
        
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(contentHash, forKey: .contentHash)
        try container.encodeIfPresent(contentType, forKey: .contentType)
        try container.encodeIfPresent(sensitiveType, forKey: .sensitiveType)
        try container.encodeIfPresent(autoDeleteAt, forKey: .autoDeleteAt)
        try container.encode(pinSuggestionDismissed, forKey: .pinSuggestionDismissed)
        
        try container.encodeIfPresent(imageMetadata, forKey: .imageMetadata)
    }
}
