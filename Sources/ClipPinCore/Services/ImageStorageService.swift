import AppKit

public enum ImageStorageError: Error, Equatable {
    case imageTooLarge
    case failedToCreatePNGData
    case failedToSave
    case failedToGenerateThumbnail
}

public class ImageStorageService {
    public static let shared = ImageStorageService()
    
    private let baseDirectory: URL
    private let maxImageSize: Int
    private let thumbnailSize = 32
    
    private var imagesDirectory: URL {
        baseDirectory.appendingPathComponent("images")
    }
    
    public init(baseDirectory: URL? = nil, maxImageSize: Int = 10_000_000) { // 10MB default
        if let baseDirectory = baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = appSupport.appendingPathComponent("ClipPin")
        }
        self.maxImageSize = maxImageSize
        // Ensure directory exists if we are using the default shared instance or specific path
        // We defer creation until use or explicit call usually, but prompt has explicit ensure method.
    }
    
    public func ensureImagesDirectoryExists() {
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }
    
    public func saveImage(_ image: NSImage, for itemId: UUID) throws -> ImageMetadata {
        ensureImagesDirectoryExists()
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ImageStorageError.failedToCreatePNGData
        }
        
        if pngData.count > maxImageSize {
            throw ImageStorageError.imageTooLarge
        }
        
        let filename = "\(itemId.uuidString).png"
        let thumbnailFilename = "\(itemId.uuidString)_thumb.png"
        
        // Save full image
        let fullPath = imagesDirectory.appendingPathComponent(filename)
        try pngData.write(to: fullPath)
        
        // Generate and save thumbnail
        let thumbnail = generateThumbnail(from: image)
        guard let thumbTiff = thumbnail.tiffRepresentation,
              let thumbBitmap = NSBitmapImageRep(data: thumbTiff),
              let thumbPNG = thumbBitmap.representation(using: .png, properties: [:]) else {
            throw ImageStorageError.failedToGenerateThumbnail
        }
        
        let thumbPath = imagesDirectory.appendingPathComponent(thumbnailFilename)
        try thumbPNG.write(to: thumbPath)
        
        return ImageMetadata(
            width: Int(image.size.width),
            height: Int(image.size.height),
            format: "png",
            fileSize: pngData.count,
            filename: filename,
            thumbnailFilename: thumbnailFilename
        )
    }
    
    public func loadImage(filename: String) -> NSImage? {
        let path = imagesDirectory.appendingPathComponent(filename)
        return NSImage(contentsOf: path)
    }
    
    public func loadThumbnail(filename: String) -> NSImage? {
        let path = imagesDirectory.appendingPathComponent(filename)
        return NSImage(contentsOf: path)
    }
    
    public func deleteImage(metadata: ImageMetadata) {
        let fullPath = imagesDirectory.appendingPathComponent(metadata.filename)
        let thumbPath = imagesDirectory.appendingPathComponent(metadata.thumbnailFilename)
        try? FileManager.default.removeItem(at: fullPath)
        try? FileManager.default.removeItem(at: thumbPath)
    }
    
    private func generateThumbnail(from image: NSImage) -> NSImage {
        let targetSize = NSSize(width: thumbnailSize, height: thumbnailSize)
        let thumbnail = NSImage(size: targetSize)
        
        thumbnail.lockFocus()
        
        let aspectWidth = targetSize.width / image.size.width
        let aspectHeight = targetSize.height / image.size.height
        // Scale aspect fit
        // Prompt said "Small 32x32 thumbnails in list".
        // Code in prompt uses aspect fill logic to draw centered?
        
        /* 
         let aspectWidth = targetSize.width / image.size.width
         let aspectHeight = targetSize.height / image.size.height
         let aspectRatio = max(aspectWidth, aspectHeight) // This is Aspect Fill
        */
        
        let aspectRatio = max(aspectWidth, aspectHeight)
        
        let scaledWidth = image.size.width * aspectRatio
        let scaledHeight = image.size.height * aspectRatio
        let x = (targetSize.width - scaledWidth) / 2
        let y = (targetSize.height - scaledHeight) / 2
        
        image.draw(in: NSRect(x: x, y: y, width: scaledWidth, height: scaledHeight), from: .zero, operation: .copy, fraction: 1.0)
        
        thumbnail.unlockFocus()
        
        return thumbnail
    }
}
