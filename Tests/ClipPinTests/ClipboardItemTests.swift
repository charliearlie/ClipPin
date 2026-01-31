import XCTest
@testable import ClipPinCore

final class ClipboardItemTests: XCTestCase {
    
    func test_clipboardItem_textType_hasCorrectDisplayLabel() {
        let item = ClipboardItem(
            id: UUID(),
            content: "Hello world this is a long string that should truncate",
            timestamp: Date()
        )
        XCTAssertEqual(item.type, .text)
        XCTAssertTrue(item.displayLabel.count <= 53) // 50 + "..."
    }

    func test_clipboardItem_imageType_hasCorrectDisplayLabel() {
        let meta = ImageMetadata(
            width: 1920,
            height: 1080,
            format: "png",
            fileSize: 245000,
            filename: "test.png",
            thumbnailFilename: "test_thumb.png"
        )
        let item = ClipboardItem(
            id: UUID(),
            type: .image,
            imageMetadata: meta,
            timestamp: Date()
        )
        XCTAssertEqual(item.displayLabel, "1920×1080")
    }

    func test_clipboardItem_imageMetadata_encodesAndDecodes() {
        let meta = ImageMetadata(
            width: 800,
            height: 600,
            format: "png",
            fileSize: 50000,
            filename: "abc.png",
            thumbnailFilename: "abc_thumb.png"
        )
        let encoded = try! JSONEncoder().encode(meta)
        let decoded = try! JSONDecoder().decode(ImageMetadata.self, from: encoded)
        XCTAssertEqual(meta, decoded)
    }

    func test_clipboardItem_migration_existingTextItemsWork() {
        // Simulate old JSON without "type" field
        let oldJSON = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "content": "test content",
            "timestamp": "2024-01-15T10:00:00Z",
            "isPinned": false,
            "copyCount": 1
        }
        """
        // Should decode with type defaulting to .text
        let data = oldJSON.data(using: .utf8)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let item = try? decoder.decode(ClipboardItem.self, from: data)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.type, .text)
    }
}
