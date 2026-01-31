# ClipPin - macOS Clipboard Manager Specification

## Overview

A lightweight, native macOS menu bar clipboard manager with first-class support for pinned items. The app lives in the menu bar, monitors clipboard changes, maintains history, and allows users to pin frequently-used snippets for quick access.

---

## Core Features

### 1. Clipboard Monitoring
- Poll `NSPasteboard.general` every 0.5 seconds for changes
- Detect and store: plain text, rich text, images, file paths
- Ignore duplicate consecutive entries
- Ignore entries from the app itself (when user clicks to copy)
- Maximum history: 50 items (configurable)
- Auto-remove oldest non-pinned items when limit reached

### 2. Pinned Items
- Users can pin any clipboard item
- Pinned items persist across app restarts
- Pinned items appear in a dedicated section at the top of the menu
- Pinned items are never auto-deleted
- Maximum pins: 20 items
- Pins can be reordered via drag-and-drop (future enhancement) or manual up/down
- Pins can be renamed with a custom label (shows label, copies original content)

### 3. Menu Bar Interface

```
┌─────────────────────────────────────────────────┐
│  📌 PINNED                                      │
│  ├─ "API Key Prod"         [📋 copy] [✕ unpin] │
│  ├─ "Email signature"      [📋 copy] [✕ unpin] │
│  └─ "Standard reply"       [📋 copy] [✕ unpin] │
├─────────────────────────────────────────────────┤
│  📋 RECENT                                      │
│  ├─ "https://example.com..."    [📌 pin]       │
│  ├─ "def calculate_total..."    [📌 pin]       │
│  ├─ "Meeting notes from..."     [📌 pin]       │
│  ├─ [Image preview]             [📌 pin]       │
│  └─ ... (up to 50 items)                       │
├─────────────────────────────────────────────────┤
│  🔍 Search...                          ⌘F      │
├─────────────────────────────────────────────────┤
│  ⚙️  Preferences...                    ⌘,      │
│  🗑️  Clear History                             │
│  ❌  Quit ClipPin                      ⌘Q      │
└─────────────────────────────────────────────────┘
```

### 4. Interactions
- **Single click** on any item → copies to clipboard
- **Right-click** on item → context menu (pin/unpin, delete, edit label)
- **Hover** on item → shows full content preview tooltip
- Visual feedback (brief highlight) when item is copied

### 5. Display Rules
- Truncate text items to ~50 characters in menu with "..."
- Show content type icon: 📝 text, 🖼️ image, 📁 file
- Show timestamp for recent items (relative: "2 min ago", "Yesterday")
- Images show small thumbnail preview

---

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open/close menu | ⌘⇧V (global, configurable) |
| Search within menu | ⌘F (when menu open) |
| Copy item 1-9 | ⌘1 through ⌘9 (when menu open) |
| Pin/unpin selected | ⌘P (when menu open) |
| Clear history | ⌘⇧K |
| Preferences | ⌘, |
| Quit | ⌘Q |

---

## Data Persistence

### Storage Location
`~/Library/Application Support/ClipPin/`

### Files
- `history.json` - Recent clipboard items
- `pins.json` - Pinned items with labels
- `preferences.json` - User settings

### Data Structure

```json
// history.json
{
  "items": [
    {
      "id": "uuid-string",
      "type": "text|image|file",
      "content": "actual content or base64 for images",
      "preview": "truncated preview text",
      "timestamp": "ISO8601 datetime",
      "appSource": "app bundle ID that created it (optional)"
    }
  ]
}

// pins.json
{
  "pins": [
    {
      "id": "uuid-string",
      "label": "Custom label or null",
      "type": "text|image|file",
      "content": "actual content",
      "preview": "truncated preview",
      "createdAt": "ISO8601 datetime",
      "order": 0
    }
  ]
}

// preferences.json
{
  "maxHistoryItems": 50,
  "maxPinnedItems": 20,
  "pollIntervalMs": 500,
  "globalHotkey": "cmd+shift+v",
  "launchAtLogin": true,
  "showInDock": false,
  "playSoundOnCopy": false,
  "theme": "system"
}
```

---

## Preferences Window

- **General**
  - Launch at login (checkbox)
  - Show in Dock (checkbox) - default off
  - Play sound on copy (checkbox)
  
- **History**
  - Maximum history items (slider: 10-100)
  - Maximum pinned items (slider: 5-50)
  - Clear history on quit (checkbox)
  
- **Shortcuts**
  - Global hotkey to open menu (hotkey recorder)
  - Enable ⌘1-9 quick copy (checkbox)

- **Appearance**
  - Theme: System / Light / Dark
  - Menu width: Compact / Standard / Wide

- **Data**
  - Export pins (button)
  - Import pins (button)
  - Clear all data (button with confirmation)

---

## Technical Architecture

### Project Structure
```
ClipPin/
├── ClipPinApp.swift              # App entry point
├── AppDelegate.swift             # Menu bar setup, lifecycle
├── Models/
│   ├── ClipboardItem.swift       # Data model for items
│   ├── PinnedItem.swift          # Pinned item with label
│   └── Preferences.swift         # Settings model
├── Services/
│   ├── ClipboardMonitor.swift    # NSPasteboard polling
│   ├── StorageService.swift      # JSON persistence
│   └── HotkeyService.swift       # Global keyboard shortcuts
├── Views/
│   ├── MenuBarView.swift         # Main menu content
│   ├── ClipboardItemView.swift   # Individual item row
│   ├── PreferencesWindow.swift   # Settings UI
│   └── SearchBar.swift           # Search component
└── Resources/
    └── Assets.xcassets           # Icons, images
```

### Key Implementation Notes

1. **Menu Bar App Configuration**
   - Set `LSUIElement = YES` in Info.plist (no dock icon by default)
   - Use `NSStatusItem` with `NSStatusBar.system`
   - Use `NSPopover` or `NSMenu` for the dropdown

2. **Clipboard Monitoring**
   - Use `Timer.scheduledTimer` for polling
   - Track `changeCount` on `NSPasteboard` to detect changes
   - Run on background thread, update UI on main thread

3. **Image Handling**
   - Store images as base64 in JSON (simple) or separate files (performant)
   - Generate thumbnails for menu display
   - Limit image storage size (e.g., max 5MB per image)

4. **Global Hotkey**
   - Use `CGEvent.tapCreate` or a library like `HotKey` (Swift package)
   - Requires Accessibility permissions

5. **Permissions Required**
   - Accessibility (for global hotkeys)
   - No network access needed
   - No special entitlements for clipboard access

---

## MVP Scope (v1.0)

### Included
- [x] Menu bar icon and dropdown
- [x] Clipboard monitoring (text only initially)
- [x] History display (last 50 items)
- [x] Pin/unpin functionality
- [x] Click to copy
- [x] Basic persistence (JSON files)
- [x] Launch at login option
- [x] Clear history

### Deferred to v1.1+
- [ ] Image/file support
- [ ] Global hotkey
- [ ] Search
- [ ] Custom labels for pins
- [ ] Drag-to-reorder pins
- [ ] Export/import
- [ ] Preferences window (use sensible defaults)

---

## Success Criteria

1. App launches to menu bar with no dock icon
2. Clipboard changes are captured within 1 second
3. Clicking an item copies it to clipboard
4. Pinned items persist across app restarts
5. Pinned items always appear above history
6. History doesn't exceed configured maximum
7. App uses < 50MB memory in normal operation
8. No perceptible CPU usage when idle

---

## Design Notes

- Keep UI minimal and fast - this is a utility app
- Match macOS system appearance (vibrancy, native controls)
- Menu should open instantly (< 100ms)
- Consider accessibility: VoiceOver support, keyboard navigation
