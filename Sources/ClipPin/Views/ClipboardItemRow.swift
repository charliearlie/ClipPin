import SwiftUI
import ClipPinCore

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onPin: () -> Void
    let onUnpin: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    @State private var showPreview = false
    @State private var hoverTimer: Timer?
    
    var body: some View {
        HStack(spacing: 8) {
            // Left: Icon or thumbnail
            itemIcon
                .frame(width: 32, height: 32)
            
            // Middle: Content label
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)
                
                if item.type == .image, let meta = item.imageMetadata {
                    Text(meta.sizeLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Right: Timestamp + actions
            if isHovering {
                actionButtons
            } else {
                Text(item.timestamp.formatted(date: .omitted, time: .shortened)) // Simplified formatting
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 36)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onCopy)
        .onHover { hovering in
            isHovering = hovering
            handleHover(hovering)
        }
        .popover(isPresented: $showPreview) {
            PreviewPanel(item: item)
        }
    }
    
    @ViewBuilder
    private var itemIcon: some View {
        switch item.type {
        case .text:
            // Use contentType to determine icon
            Image(systemName: iconFor(item.contentType ?? .plain))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
        case .image:
            if let thumbFilename = item.imageMetadata?.thumbnailFilename,
               let thumbnail = ImageStorageService.shared.loadThumbnail(filename: thumbFilename) {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 4) {
             HoverActionButton(
                imageName: item.isPinned ? "pin.fill" : "pin",
                color: item.isPinned ? .accentColor : .secondary,
                tooltip: item.isPinned ? "Unpin" : "Pin",
                yOffset: 1,
                action: item.isPinned ? onUnpin : onPin
             )
             
             HoverActionButton(
                imageName: "trash",
                color: .secondary,
                tooltip: "Delete",
                action: onDelete
             )
        }
    }
    
    private func handleHover(_ isHovering: Bool) {
        hoverTimer?.invalidate()
        if isHovering {
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.3, repeats: false) { _ in // 1.3s (was 0.8s + 0.5s)
                showPreview = true
            }
        } else {
            showPreview = false
        }
    }
    
    private func iconFor(_ type: ContentType) -> String {
        switch type {
        case .url: return "globe"
        case .email: return "envelope"
        case .phone: return "phone"
        case .json: return "curlybraces"
        case .colorHex: return "paintpalette"
        case .plain: return "text.alignleft"
        }
    }
}

struct HoverActionButton: View {
    let imageName: String
    let color: Color
    let tooltip: String
    var yOffset: CGFloat = 0
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: imageName)
                .imageScale(.medium)
                .foregroundColor(isHovering ? .primary : color)
                .frame(width: 20, height: 20)
                .offset(y: yOffset)
                .background(
                    Circle()
                        .fill(isHovering ? Color.secondary.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hover in
            isHovering = hover
        }
    }
}
