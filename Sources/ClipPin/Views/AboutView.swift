import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 8) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            
            // App Name
            Text("ClipPin")
                .font(.system(size: 20, weight: .bold))
            
            // Version and Build
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(build))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tagline
            Text("A clipboard manager with pinning")
                .font(.caption)
                .padding(.top, 4)
            
            Spacer()
                .frame(height: 8)
                
            // Copyright
            if let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String {
                 Text(copyright)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                 Text("© 2026 Charlie Waite")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // GitHub Link
            Link("GitHub Repository", destination: URL(string: "https://github.com/charliearlie/ClipPin")!)
                .font(.caption)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 300, height: 220)
    }
}
