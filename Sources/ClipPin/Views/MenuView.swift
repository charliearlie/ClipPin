import SwiftUI
import ClipPinCore

struct MenuView: View {
    @StateObject private var monitor = ClipboardMonitor()
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            TextField("Search history...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(8)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    if filteredPinnedItems.isEmpty && filteredRecentItems.isEmpty {
                         Text("No results")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // PINNED SECTION
                    if !filteredPinnedItems.isEmpty {
                        SectionHeader(title: "📌 PINNED")
                        
                        ForEach(filteredPinnedItems) { item in
                            ClipboardItemRow(
                                item: item,
                                onCopy: { handle(.copy, for: item) },
                                onPin: { handle(.pin, for: item) },
                                onUnpin: { handle(.unpin, for: item) },
                                onDelete: { handle(.delete, for: item) }
                            )
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                    }
                    
                    // RECENT SECTION
                    if !filteredRecentItems.isEmpty {
                         SectionHeader(title: "📋 RECENT")
                        
                        ForEach(filteredRecentItems) { item in
                            ClipboardItemRow(
                                item: item,
                                onCopy: { handle(.copy, for: item) },
                                onPin: { handle(.pin, for: item) },
                                onUnpin: { handle(.unpin, for: item) },
                                onDelete: { handle(.delete, for: item) }
                            )
                        }
                    } else if searchText.isEmpty { 
                        // Only show "No recent usage" if not searching, otherwise "No results" covers it
                        SectionHeader(title: "📋 RECENT")
                        Text("No recent usage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .frame(maxHeight: 400) // Limit height
            
            Divider()
            
            // Footer controls
            VStack(spacing: 4) {
                 // Pause Toggle
                Button(action: {
                    monitor.preferences.isPaused.toggle()
                }) {
                    HStack {
                        Image(systemName: monitor.preferences.isPaused ? "play.fill" : "pause.fill")
                        Text(monitor.preferences.isPaused ? "Resume Capture" : "Pause Capture")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .controlSize(.small)

                Toggle("Launch at Login", isOn: $monitor.preferences.launchAtLogin)
                    .toggleStyle(.switch) // or checkbox, switch looks modern
                    .font(.caption)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .controlSize(.mini)
                
                Divider()
                    .padding(.horizontal)
                
                Button("About ClipPin") {
                    NSApp.sendAction(#selector(AppDelegate.openAboutWindow), to: nil, from: nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .padding(.horizontal)
                
                HStack {
                    Button("Clear History") {
                        monitor.clearHistory()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    
                    Spacer()
                    
                    Button("Quit ClipPin") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 320)
        .padding(.top, 8)
    }
    
    private func handle(_ action: MenuAction, for item: ClipboardItem) {
        print("Handling action: \(action) for item: \(item.id)")
        switch action {
        case .copy:
            monitor.copyToClipboard(item: item)
             NSApp.sendAction(#selector(AppDelegate.closePopover(_:)), to: nil, from: nil)
             // Clear search on close (optional but good UX)
             searchText = ""

        case .pin:
            print("Pinning item...")
            monitor.pin(item: item)
            searchText = "" 
        case .unpin:
            print("Unpinning item...")
            monitor.unpin(item: item)
        case .delete:
            monitor.delete(item: item)
        }
    }
    
    var filteredPinnedItems: [ClipboardItem] {
        if searchText.isEmpty { return monitor.pinnedItems }
        return monitor.pinnedItems.filter { ($0.content ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    var filteredRecentItems: [ClipboardItem] {
        if searchText.isEmpty { return monitor.recentItems }
        return monitor.recentItems.filter { ($0.content ?? "").localizedCaseInsensitiveContains(searchText) }
    }
}

enum MenuAction {
    case copy
    case pin
    case unpin
    case delete
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.secondary) // Grayish
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuItemRow: View {
    let item: ClipboardItem
    let isPinned: Bool
    let actionHandler: (MenuAction) -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Main clickable area (Copy)
            Button(action: {
                actionHandler(.copy)
            }) {
                HStack {
                    // Sensitive Data Warning
                    if let sensitiveType = item.sensitiveType {
                        Text("⚠️")
                            .help("This looks like \(sensitiveType.rawValue.capitalized) details")
                            .padding(.trailing, 4)
                    }
                    
                    // Pin Suggestion
                    if !isPinned && item.copyCount >= 3 && !item.pinSuggestionDismissed {
                        Text("📌?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .help("Pin this? Copied \(item.copyCount) times")
                            .padding(.trailing, 4)
                    }
                    
                    // Quick Action Button
                    if let contentType = item.contentType, let quickAction = quickActionFor(contentType) {
                         // Keep this button separate so it doesn't trigger copy?
                         // User said "whole row clickable". 
                         // Ideally quick action is a secondary action inside.
                         // Swift UI Buttons inside Buttons can be tricky.
                         // Let's rely on the row copy, but maybe the quick action is just an icon that we click specifically?
                         // Or if we click the row, it copies. If we click the icon, it does action.
                         // To achieve this, we use .buttonStyle(.plain) for the container button
                         Button(action: {
                             performQuickAction(quickAction, content: item.content ?? "")
                         }) {
                             Text(quickAction.icon)
                         }
                         .buttonStyle(.plain)
                         .help(quickAction.tooltip)
                         .padding(.trailing, 4)
                         // Highlighting issue: nested buttons might steal hover.
                    } else if item.contentType == .colorHex {
                         RoundedRectangle(cornerRadius: 2)
                             .fill(Color(hex: item.content ?? "#000000"))
                             .frame(width: 12, height: 12)
                             .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.gray, lineWidth: 1))
                             .padding(.trailing, 4)
                    }
                    
                    Text(truncatedContent)
                        .lineLimit(1)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle()) // Make entire HStack area clickable
            }
            .buttonStyle(.plain) // Important for custom look and nesting
            .frame(maxWidth: .infinity)
            
            // Actions Area (visible on hover or if pinned)
            HStack(spacing: 4) {
                 // Pin/Unpin
                 HoverIconButton(
                    imageName: isPinned ? "pin.fill" : "pin",
                    color: isPinned ? .accentColor : .secondary,
                    tooltip: isPinned ? "Unpin item" : "Pin item" // Distinct tooltips
                 ) {
                     actionHandler(isPinned ? .unpin : .pin)
                 }
                 
                 // Delete
                 HoverIconButton(
                    imageName: "trash",
                    color: .secondary,
                    tooltip: "Delete item"
                 ) {
                     actionHandler(.delete)
                 }
            }
            .padding(.leading, 8)
            .opacity(isHovering || isPinned ? 1 : 0) // Hide unless hovering or pinned
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .onHover { hover in
            isHovering = hover
        }
        .padding(.horizontal, 6) // Outer padding for the list item
    }
    
    var truncatedContent: String {
        formatContent(item)
    }

    private func formatContent(_ item: ClipboardItem) -> String {
        guard let content = item.content else { return "Image" }
        if content.count > 50 {
            return String(content.prefix(50)) + "..."
        }
        return content.replacingOccurrences(of: "\n", with: " ")
    }
    
    // Quick Actions Logic
    struct QuickAction {
        let icon: String
        let tooltip: String
        let type: ContentType
    }
    
    func quickActionFor(_ type: ContentType) -> QuickAction? {
        switch type {
        case .url: return QuickAction(icon: "🌐", tooltip: "Open in Browser", type: .url)
        case .email: return QuickAction(icon: "✉️", tooltip: "Compose Email", type: .email)
        case .phone: return QuickAction(icon: "📞", tooltip: "Call / Copy Digits", type: .phone)
        case .json: return QuickAction(icon: "📑", tooltip: "Format JSON (Copy)", type: .json)
        default: return nil
        }
    }
    
    func performQuickAction(_ action: QuickAction, content: String) {
        switch action.type {
        case .url:
            if let url = URL(string: content) {
                NSWorkspace.shared.open(url)
            }
        case .email:
            if let url = URL(string: "mailto:\(content)") {
                NSWorkspace.shared.open(url)
            }
        case .phone:
            // Strip formatting and copy? Or open tel:?
            // "Copy digits 📞" strips formatting
            let digits = content.filter { $0.isNumber }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(digits, forType: .string)
        case .json:
            // "Format 📋" copies prettified
            if let data = content.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data, options: []),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(prettyString, forType: .string)
            }
        default: break
        }
    }
}

struct HoverIconButton: View {
    let imageName: String
    let color: Color
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: imageName)
                .foregroundColor(isHovering ? .primary : color) // Highlight on hover
                .font(.system(size: 11))
                .padding(4)
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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
