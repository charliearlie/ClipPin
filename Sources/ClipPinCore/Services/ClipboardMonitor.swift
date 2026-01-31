import AppKit
import Combine

public extension Notification.Name {
    static let clipPinPreferencesChanged = Notification.Name("com.clippin.preferencesChanged")
}

public class ClipboardMonitor: ObservableObject {
    @Published public var recentItems: [ClipboardItem] = [] {
        didSet {
            storageService.saveHistory(recentItems)
        }
    }
    @Published public var pinnedItems: [ClipboardItem] = [] {
        didSet {
            storageService.savePins(pinnedItems)
        }
    }
    
    @Published public var preferences: Preferences = Preferences() {
        didSet {
            storageService.savePreferences(preferences)
            // Handle side effects
            if preferences.launchAtLogin != oldValue.launchAtLogin {
                LaunchAtLoginService.shared.isEnabled = preferences.launchAtLogin
            }
            
            // Update menubar icon via Notification since we can't depend on AppDelegate here
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .clipPinPreferencesChanged, object: nil, userInfo: ["isPaused": self.preferences.isPaused])
            }
        }
    }
    
    private var timer: Timer?
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private let storageService: StorageService
    
    public init(storageService: StorageService = .shared) {
        self.storageService = storageService
        self.lastChangeCount = pasteboard.changeCount
        // Load persisted data
        // For tests, loadHistory/loadPins might read from user's disk if not patched.
        var loadedRecent = storageService.loadHistory()
        // Sanitize: Recent items should never be pinned
        for i in 0..<loadedRecent.count {
            if loadedRecent[i].isPinned {
                print("WARNING: Found pinned item in recent items: \(loadedRecent[i].content?.prefix(10) ?? "")... Fixing.")
                loadedRecent[i].isPinned = false
            }
        }
        self.recentItems = loadedRecent
        
        self.pinnedItems = storageService.loadPins()
        
        // Sanitize: Pinned items must have isPinned = true
        for i in 0..<self.pinnedItems.count {
             if !self.pinnedItems[i].isPinned {
                 self.pinnedItems[i].isPinned = true
             }
        }
        
        let loadedPrefs = storageService.loadPreferences()
        self.preferences = loadedPrefs
        
        // Sync LaunchAtLogin state with system if needed, or enforce pref
        // LaunchAtLoginService.shared.isEnabled = loadedPrefs.launchAtLogin 
        // (Be careful not to loop or error on init if permission denied, but good to sync)
        
        startMonitoring()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        // Skip if paused
        if preferences.isPaused { 
             // Update icon to indicate pause if not already updated?
             // Ideally we do this reactively.
             return 
        }

        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            if let newString = pasteboard.string(forType: .string) {
                // Ignore duplicates if same as most recent
                if let lastItem = recentItems.first, lastItem.type == .text, lastItem.content == newString {
                     // Still increment usage count?
                     var updatedItem = lastItem
                     updatedItem.copyCount += 1
                     recentItems[0] = updatedItem
                     return
                }
                
                // Do not add if it is already pinned?
                if let index = pinnedItems.firstIndex(where: { $0.type == .text && $0.content == newString }) {
                     return
                }

                // Check for duplicate in recent history that isn't the first item?
                if let index = recentItems.firstIndex(where: { $0.type == .text && $0.content == newString }) {
                    var existingItem = recentItems[index]
                    existingItem.copyCount += 1
                    existingItem.timestamp = Date()
                    recentItems.remove(at: index)
                    recentItems.insert(existingItem, at: 0)
                    return
                }

                let detectedType = ContentTypeDetector.shared.detect(content: newString)
                var sensitiveType = SensitiveDataDetector.shared.detect(content: newString)
                
                // Handle rules
                var autoDeleteDate: Date? = nil
                
                if let type = sensitiveType {
                    let rule = preferences.sensitiveDataRules[type.rawValue] ?? "askEachTime"
                    
                    if rule == "neverStore" {
                        return 
                    } else if rule == "autoDelete30s" {
                        autoDeleteDate = Date().addingTimeInterval(30)
                    }
                }
                
                let newItem = ClipboardItem(
                    content: newString,
                    contentType: detectedType,
                    sensitiveType: sensitiveType,
                    autoDeleteAt: autoDeleteDate
                )
                recentItems.insert(newItem, at: 0)
                
                // Limit to maxHistoryItems
                if recentItems.count > preferences.maxHistoryItems {
                    recentItems.removeLast()
                }
                
                // Schedule auto-delete if needed
                if let deleteDate = autoDeleteDate {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                        self?.autoDelete(itemId: newItem.id)
                    }
                }
            } else if pasteboard.canReadObject(forClasses: [NSImage.self], options: nil) {
                // Handle Image
                if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage],
                   let image = images.first {
                    
                    let itemId = UUID()
                    do {
                        let metadata = try ImageStorageService.shared.saveImage(image, for: itemId)
                        
                        let newItem = ClipboardItem(
                            id: itemId,
                            type: .image,
                            imageMetadata: metadata
                        )
                        recentItems.insert(newItem, at: 0)
                        
                        // Limit to maxHistoryItems (shared limit for now, or separate? Prompt said "Max 20 images in history" in Task 4, but maybe total limit applies here too?)
                        // Prompt Task 4 says "Storage Service - Image Limit Enforcement". 
                        // "Max 20 images in history, max 10MB per image".
                        // Logic for enforcing 20 images might be separate or integrated?
                        // For now just add to recent items.
                         if recentItems.count > preferences.maxHistoryItems {
                            recentItems.removeLast()
                        }
                    } catch {
                        print("Failed to save clipboard image: \(error)")
                    }
                }
            }
        }
    }
    
    private func autoDelete(itemId: UUID) {
        // Remove from recent items if it exists
        if let index = recentItems.firstIndex(where: { $0.id == itemId }) {
            recentItems.remove(at: index)
        }
    }
    
    public func pin(item: ClipboardItem) {
        var newItem = item
        newItem.isPinned = true
        newItem.timestamp = Date() // Refresh timestamp or keep original? Keep original usually better but for sorting maybe new.
        
        // Check if already pinned (shouldn't be based on UI, but safety)
        if !pinnedItems.contains(where: { $0.id == item.id }) {
             // Max 20 pins
            if pinnedItems.count < 20 {
                pinnedItems.append(newItem)
                // Remove from recent items logic? 
                // "Pins stay at top of menu". Usually means they are removed from 'Recent' list or just duplicated.
                // Let's remove from recent if we pin it to avoid duplication in UI
                recentItems.removeAll(where: { $0.id == item.id })
            }
        }
    }
    
    public func unpin(item: ClipboardItem) {
        print("Attempting to unpin item: \(item.id)")
        if let index = pinnedItems.firstIndex(where: { $0.id == item.id }) {
            print("Found item at index \(index), removing...")
            var itemToUnpin = pinnedItems[index]
            itemToUnpin.isPinned = false
            pinnedItems.remove(at: index)
            
            // Add back to top of recent
            recentItems.insert(itemToUnpin, at: 0)
            print("Item unpinned and moved to recent.")
        } else {
            print("Item not found in pinnedItems!")
        }
    }
    
    public func delete(item: ClipboardItem) {
        if let index = pinnedItems.firstIndex(where: { $0.id == item.id }) {
            pinnedItems.remove(at: index)
        } else if let index = recentItems.firstIndex(where: { $0.id == item.id }) {
            recentItems.remove(at: index)
        }
    }
    
    public func copyToClipboard(item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.type {
        case .text:
            if let content = item.content {
                pasteboard.setString(content, forType: .string)
            }
        case .image:
            // TODO: partial implementation for now, will fully implement in Task 3
            if let meta = item.imageMetadata,
               let image = ImageStorageService.shared.loadImage(filename: meta.filename) {
                pasteboard.writeObjects([image])
            }
        }
        
        // Update lastChangeCount so we don't re-capture this as a new external copy
        // However, setting string increases changeCount immediately.
        // We need to capture the new changeCount.
        lastChangeCount = pasteboard.changeCount
    }
    
    public func clearHistory() {
        recentItems.removeAll()
    }
    
    deinit {
        timer?.invalidate()
    }
}
