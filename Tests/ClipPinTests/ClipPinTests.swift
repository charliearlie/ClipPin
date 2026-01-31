import XCTest
@testable import ClipPinCore

final class ClipPinTests: XCTestCase {
    
    // Mock Persistence or use in-memory?
    // StorageService writes to disk. For tests, we might want to mock it or ensure it uses a temp dir?
    // Since StorageService is a singleton using FileManager, interacting with it in tests might persist to real disk if not careful.
    // Ideally we inject a mock StorageService or configure it to use a temp path.
    // For this MVP test, we'll try to rely on ClipboardMonitor's in-memory state manipulation, 
    // but Monitor loads from disk on init.
    // We should patch StorageService or check if we can test pure logic without it.
    
    // The issue is in `ClipboardMonitor.unpin`.
    
    func testUnpinRemovesFromPinnedAndAddsToRecent() {
        // Arrange
        let storage = StorageService(inMemory: true)
        let monitor = ClipboardMonitor(storageService: storage) 
        
        monitor.pinnedItems = []
        monitor.recentItems = []
        
        let item = ClipboardItem(content: "Test Item", isPinned: true)
        monitor.pinnedItems.append(item)
        
        XCTAssertEqual(monitor.pinnedItems.count, 1)
        XCTAssertEqual(monitor.recentItems.count, 0)
        
        // Act
        monitor.unpin(item: item)
        
        // Assert
        XCTAssertEqual(monitor.pinnedItems.count, 0, "Item should be removed from pinnedItems")
        XCTAssertEqual(monitor.recentItems.count, 1, "Item should be added to recentItems")
        XCTAssertFalse(monitor.recentItems.first?.isPinned ?? true, "Item should effectively be unpinned in recent list")
    }
}
