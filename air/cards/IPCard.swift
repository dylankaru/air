import SwiftUI

struct IPCard: View {
    @Environment(\.activeTheme) private var theme
    
    @State private var ipv4Address: String = "0.0.0.0"
    @State private var ipv6Address: String = "0:0:0:0"
    @State private var isLoading: Bool = false
    
    var body: some View {
        Card {
            if ipv4Address != ipv6Address {
                VStack(spacing: 12) {
                    Text("IPv4: " + ipv4Address)
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(theme.textColour)
                    
                    Text("IPv6: " + ipv6Address)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(theme.textColour)
                        .lineLimit(1)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding()
            } else {
                VStack(spacing: 12) {
                    Text("IPv4: " + ipv4Address)
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(theme.textColour)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding()
            }
        }
        .task {
            fetchPublicIP()
        }
    }
    
    private func fetchPublicIP() {
        isLoading = true
        ipv4Address = "Fetching..."
        ipv6Address = "Fetching..."

        DispatchQueue.global(qos: .userInitiated).async {
            let ipv4 = pullFromTerminal("/usr/bin/curl", arguments: ["-s", "-4", "https://ifconfig.me"])
            let ipv6 = pullFromTerminal("/usr/bin/curl", arguments: ["-s", "-6", "https://ifconfig.me"])

            DispatchQueue.main.async {
                self.ipv4Address = ipv4.trimmingCharacters(in: .whitespacesAndNewlines)
                self.ipv6Address = ipv6.trimmingCharacters(in: .whitespacesAndNewlines)
                self.isLoading = false
            }
        }
    }

    private func pullFromTerminal(_ launchPath: String, arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                return output
            } else {
                return "No output returned."
            }
        } catch {
            return "Error executing command: \(error.localizedDescription)"
        }
    }
}
