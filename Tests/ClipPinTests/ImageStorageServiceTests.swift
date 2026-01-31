import XCTest
import AppKit
@testable import ClipPinCore

final class ImageStorageServiceTests: XCTestCase {
    
    func test_imageStorage_createsImagesDirectory() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let service = ImageStorageService(baseDirectory: tempDir)
        
        service.ensureImagesDirectoryExists()
        
        let imagesDir = tempDir.appendingPathComponent("images")
        XCTAssertTrue(FileManager.default.fileExists(atPath: imagesDir.path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_imageStorage_savesAndLoadsImage() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        // Ensure directory exists for test
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let service = ImageStorageService(baseDirectory: tempDir)
        
        // Create a simple test image (100x100 red)
        let testImage = createTestImage(width: 100, height: 100)
        let itemId = UUID()
        
        do {
            let metadata = try service.saveImage(testImage, for: itemId)
            
            XCTAssertEqual(metadata.width, 100)
            XCTAssertEqual(metadata.height, 100)
            XCTAssertTrue(metadata.filename.contains(itemId.uuidString))
            
            // Verify files exist
            let imagesDir = tempDir.appendingPathComponent("images")
            XCTAssertTrue(FileManager.default.fileExists(atPath: imagesDir.appendingPathComponent(metadata.filename).path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: imagesDir.appendingPathComponent(metadata.thumbnailFilename).path))
            
        } catch {
            XCTFail("Failed to save image: \(error)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_imageStorage_generatesThumbnail_correctSize() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let service = ImageStorageService(baseDirectory: tempDir)
        
        let testImage = createTestImage(width: 1920, height: 1080)
        let itemId = UUID()
        
        do {
            let metadata = try service.saveImage(testImage, for: itemId)
            
            let thumbnailPath = tempDir.appendingPathComponent("images").appendingPathComponent(metadata.thumbnailFilename)
            let thumbnail = NSImage(contentsOf: thumbnailPath)
            
            XCTAssertNotNil(thumbnail)
            XCTAssertEqual(thumbnail?.size.width ?? 0, 32, accuracy: 1)
            XCTAssertEqual(thumbnail?.size.height ?? 0, 32, accuracy: 1)
        } catch {
            XCTFail("Failed to save image: \(error)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_imageStorage_deletesImageFiles() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let service = ImageStorageService(baseDirectory: tempDir)
        
        let testImage = createTestImage(width: 100, height: 100)
        let itemId = UUID()
        let metadata = try! service.saveImage(testImage, for: itemId)
        
        let imagesDir = tempDir.appendingPathComponent("images")
        let fullPath = imagesDir.appendingPathComponent(metadata.filename)
        let thumbPath = imagesDir.appendingPathComponent(metadata.thumbnailFilename)
        
        // Verify files exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: fullPath.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: thumbPath.path))
        
        // Delete
        service.deleteImage(metadata: metadata)
        
        // Verify files gone
        XCTAssertFalse(FileManager.default.fileExists(atPath: fullPath.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: thumbPath.path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_imageStorage_rejectsOversizedImages() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let service = ImageStorageService(baseDirectory: tempDir, maxImageSize: 1000) // 1KB limit for test
        
        let largeImage = createTestImage(width: 1000, height: 1000) // Will exceed 1KB
        let itemId = UUID()
        
        XCTAssertThrowsError(try service.saveImage(largeImage, for: itemId)) { error in
            XCTAssertEqual(error as? ImageStorageError, .imageTooLarge)
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    // Helper
    func createTestImage(width: Int, height: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }
}
