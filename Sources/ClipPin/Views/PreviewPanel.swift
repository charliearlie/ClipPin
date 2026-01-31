import SwiftUI
import ClipPinCore

struct PreviewPanel: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch item.type {
            case .text:
                ScrollView {
                    Text(item.content ?? "")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                }
                .frame(maxWidth: 400, maxHeight: 300)
                
                if let content = item.content {
                    Text("\(content.count) characters • \(item.timestamp.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
            case .image:
                if let filename = item.imageMetadata?.filename,
                   let image = ImageStorageService.shared.loadImage(filename: filename) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 400, maxHeight: 400)
                }
                
                if let meta = item.imageMetadata {
                    Text("\(meta.dimensionsLabel) • \(meta.format.uppercased()) • \(meta.sizeLabel) • \(item.timestamp.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

// NSVisualEffectView wrapper for blur effect
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
