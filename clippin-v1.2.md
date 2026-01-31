# ClipPin v1.2 Specification - Image Support

## Overview

Add image clipboard support while maintaining a clean, consistent UI. Images and text share the same list with uniform row heights. Full previews available via hover or spacebar (Quick Look style).

---

## Design Principles

1. **Uniform row height** - Every row is identical height (~36pt), whether text or image
2. **Thumbnails, not full images** - Small 32x32 square preview, enough to recognise
3. **Detail on demand** - Full content via hover (0.5s delay) or spacebar
4. **Mixed feed** - No tabs, no separate sections for images vs text

---

## Visual Design

### Row Layout (Fixed 36pt height)

**Text Row:**
```
┌──────────────────────────────────────────────────────────────┐
│ 📝  "const handleSubmit = async (data) =>..."    2m    [📌] │
│ ↑    ↑                                            ↑      ↑   │
│ icon  content (truncated 50 chars)               age   action│
└──────────────────────────────────────────────────────────────┘
```

**Image Row:**
```
┌──────────────────────────────────────────────────────────────┐
│ [32x32 thumb]  Screenshot • 1420×900             2m    [📌] │
│ ↑               ↑                                 ↑      ↑   │
│ thumbnail       label + dimensions               age   action│
└──────────────────────────────────────────────────────────────┘
```

### Complete Menu Structure

```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 Search...                                                │
├─────────────────────────────────────────────────────────────┤
│ 📌 PINNED                                                   │
│ ├─ 📝  "API endpoint for production..."       1d     [⊗]  │
│ ├─ [img] Logo.png • 256×256                   3d     [⊗]  │
│ └─ 📝  "SELECT * FROM users WHERE..."         1w     [⊗]  │
├─────────────────────────────────────────────────────────────┤
│ 📋 RECENT                                                   │
│ ├─ 📝  "https://github.com/charlie/clip..."   now    [📌] │
│ ├─ [img] Screenshot • 1420×900                2m     [📌] │
│ ├─ 📝  "const result = await fetch(..."       5m     [📌] │
│ ├─ [img] Image • 800×600                      12m    [📌] │
│ ├─ ⚠️  "4532 •••• •••• 1234"                  15m    [📌] │
│ └─ 📝  "Meeting notes: discussed the..."      1h     [📌] │
├─────────────────────────────────────────────────────────────┤
│   ⏸️ Pause Capture                                          │
│   Launch at Login ✓                                         │
├─────────────────────────────────────────────────────────────┤
│   Clear History                                             │
│   Quit ClipPin                              ⌘Q              │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Look Preview

### Trigger
- **Hover** for 0.5 seconds on any row, OR
- **Spacebar** when row is focused/highlighted

### Preview Panel
- Floating panel appears near the row (not covering it)
- Semi-transparent background with blur (NSVisualEffectView)
- Dismisses when mouse leaves or spacebar pressed again

### Text Preview
```
┌────────────────────────────────────────────┐
│ const handleSubmit = async (data) => {     │
│   const response = await fetch('/api', {   │
│     method: 'POST',                        │
│     body: JSON.stringify(data)             │
│   });                                      │
│   return response.json();                  │
│ }                                          │
│                                            │
│ 156 characters • Copied 2 minutes ago      │
└────────────────────────────────────────────┘
```

### Image Preview
```
┌────────────────────────────────────────────┐
│                                            │
│         [Full resolution image             │
│          scaled to fit max                 │
│          400×400 while                     │
│          preserving aspect ratio]          │
│                                            │
│ 1420×900 • PNG • 245 KB • 2 minutes ago   │
└────────────────────────────────────────────┘
```

---

## Image Handling

### Capture
- Monitor `NSPasteboard` for image types: `NSImage`, `TIFF`, `PNG`, `JPEG`
- Store as PNG data (good balance of quality and size)
- Generate 32×32 thumbnail on capture (for list display)
- Extract dimensions from image data

### Storage

**Structure:**
```
~/Library/Application Support/ClipPin/
├── history.json        # metadata only
├── pins.json           # metadata only
├── images/             # actual image data
│   ├── {uuid}.png      # full image
│   └── {uuid}_thumb.png # 32×32 thumbnail
└── preferences.json
```

**Why separate files for images:**
- JSON stays small and fast to parse
- Images can be large; don't want to base64 encode into JSON
- Easy to delete old images when clearing history
- Thumbnails load fast for list rendering

### Image Metadata in JSON

```json
{
  "id": "uuid-string",
  "type": "image",
  "timestamp": "2024-01-15T10:30:00Z",
  "isPinned": false,
  "pinOrder": null,
  "copyCount": 1,
  "imageMetadata": {
    "width": 1420,
    "height": 900,
    "format": "png",
    "fileSize": 245000,
    "filename": "uuid-string.png",
    "thumbnailFilename": "uuid-string_thumb.png"
  }
}
```

### Size Limits

| Limit | Value | Rationale |
|-------|-------|-----------|
| Max image size to capture | 10 MB | Larger is probably not intentional |
| Max stored images | 20 | Images take space; keep recent only |
| Thumbnail size | 32×32 | Fits row height, fast to render |
| Preview max size | 400×400 | Fits nicely in popover area |

When image limit reached, delete oldest non-pinned image.

---

## Updated Data Model

```swift
enum ClipboardItemType: String, Codable {
    case text
    case image
}

struct ImageMetadata: Codable, Equatable {
    let width: Int
    let height: Int
    let format: String  // "png", "jpeg", etc.
    let fileSize: Int   // bytes
    let filename: String
    let thumbnailFilename: String
}

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let type: ClipboardItemType
    var timestamp: Date
    var isPinned: Bool
    var pinOrder: Int?
    var copyCount: Int = 1
    
    // Text-specific
    var content: String?
    var contentHash: String?
    var contentType: ContentType?  // url, email, etc.
    var sensitiveType: SensitiveDataType?
    
    // Image-specific
    var imageMetadata: ImageMetadata?
    
    // Computed
    var displayLabel: String {
        switch type {
        case .text:
            return content?.prefix(50).description ?? ""
        case .image:
            guard let meta = imageMetadata else { return "Image" }
            return "\(meta.width)×\(meta.height)"
        }
    }
}
```

---

## User Interactions

| Action | Text Item | Image Item |
|--------|-----------|------------|
| Single click | Copy text to clipboard | Copy image to clipboard |
| Hover 0.5s | Show full text preview | Show full image preview |
| Spacebar | Show full text preview | Show full image preview |
| Pin button | Pin to top | Pin to top |
| Right-click | Context menu | Context menu |

### Context Menu (Right-Click)

**Text items:**
- Copy
- Copy as Plain Text
- Pin / Unpin
- Delete

**Image items:**
- Copy
- Save to Desktop
- Pin / Unpin  
- Delete

---

## Search Behavior

Search should filter both text and images:

- **Text**: Search in content (existing behavior)
- **Images**: Search in filename if available, otherwise skip (images without names won't appear in search results, which is fine)

---

## Performance Considerations

1. **Thumbnail loading**: Load thumbnails lazily as rows become visible
2. **Full image loading**: Only load full image when preview requested
3. **Memory**: Don't keep all images in memory; load from disk on demand
4. **Cleanup**: When deleting history items, also delete associated image files

---

## Migration from v1.1

- Existing text-only history.json continues to work
- Add `type: "text"` to existing items on first load
- Create `images/` directory on first image capture

---

## Testing Requirements

### Unit Tests

```swift
// ImageMetadata
- test_imageMetadata_calculatesDisplayLabel
- test_imageMetadata_encodesAndDecodes

// ClipboardItem
- test_clipboardItem_textType_returnsCorrectDisplayLabel
- test_clipboardItem_imageType_returnsCorrectDisplayLabel
- test_clipboardItem_migrationAddsTypeField

// Thumbnail Generation
- test_thumbnailGenerator_createsThumbnail_correctSize
- test_thumbnailGenerator_preservesAspectRatio
- test_thumbnailGenerator_handlesVariousFormats

// Image Storage
- test_imageStorage_savesFullImage
- test_imageStorage_savesThumbnail
- test_imageStorage_deletesImageFiles
- test_imageStorage_handlesCorruptedImages

// Clipboard Monitor
- test_clipboardMonitor_detectsImageContent
- test_clipboardMonitor_ignoresOversizedImages
- test_clipboardMonitor_extractsImageDimensions

// Storage Service
- test_storageService_createsImagesDirectory
- test_storageService_migratesOldHistory
- test_storageService_enforcesImageLimit
```

### Integration Tests

```swift
- test_copyImage_appearsInHistory
- test_clickImageRow_copiesToClipboard
- test_pinImage_persistsAcrossRestart
- test_clearHistory_deletesImageFiles
- test_imageLimit_deletesOldestWhenExceeded
```

### Manual Test Scenarios

1. Copy screenshot (Cmd+Shift+4) → appears in ClipPin with correct dimensions
2. Copy image from browser → appears in ClipPin
3. Click image in ClipPin → paste elsewhere works
4. Hover over image row → full preview appears
5. Press spacebar on image row → full preview appears
6. Pin an image → persists after restart
7. Copy 25 images → oldest 5 non-pinned are removed
8. Clear history → images folder is emptied