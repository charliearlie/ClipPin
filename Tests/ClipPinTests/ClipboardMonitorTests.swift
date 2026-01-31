import XCTest
import AppKit
@testable import ClipPinCore

final class ClipboardMonitorTests: XCTestCase {
    
    func test_clipboardMonitor_detectsImageContent() {
        let monitor = ClipboardMonitor()
        let testImage = createTestImage(width: 100, height: 100)
        
        // Simulate image on pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([testImage])
        
        // Wait for detection cycle? Or manually trigger check?
        // Monitor uses a timer, so we should allow it to fire or call checkClipboard manually if private/internal.
        // checkClipboard is private. We can wait with expectation.
        
        let expectation = XCTestExpectation(description: "Image detected")
        
        // Observe changes
        let cancellable = monitor.$recentItems.sink { items in
            if let first = items.first, first.type == .image {
                expectation.fulfill()
            }
        }
        
        // Wait a bit longer than the timer interval (0.5s)
        wait(for: [expectation], timeout: 2.0)
        cancellable.cancel()
    }

    func test_clipboardMonitor_detectsTextContent() {
        let monitor = ClipboardMonitor()
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("Hello world for test", forType: .string)
        
        let expectation = XCTestExpectation(description: "Text detected")
        
        let cancellable = monitor.$recentItems.sink { items in
            if let first = items.first, first.type == .text, first.content == "Hello world for test" {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
        cancellable.cancel()
    }

    func test_clipboardMonitor_prefersTextOverImage() {
        // When both text and image are present (e.g., copied from rich app),
        // prefer text as it's more likely what user wants
        let monitor = ClipboardMonitor()
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("Some text priority", forType: .string)
        // Also add image
        let testImage = createTestImage(width: 50, height: 50)
        pasteboard.writeObjects([testImage])
        
        let expectation = XCTestExpectation(description: "Text preferred")
        
        let cancellable = monitor.$recentItems.sink { items in
            if let first = items.first, first.content == "Some text priority" {
                XCTAssertEqual(first.type, .text)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
        cancellable.cancel()
    }
    
    // Helper
    func createTestImage(width: Int, height: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        image.unlockFocus()
        return image
    }
}
