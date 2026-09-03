//
//  SystemStatsCard.swift
//  air
//
//  Created by Dylan Karunanayake on 23/8/2026.
//

import SwiftUI
import Foundation
import IOKit.ps
import IOKit
internal import Combine

struct AppUsage: Identifiable {
    let id = UUID()
    let name: String
    let cpuPercent: Double
}

class SystemMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var gpuUsage: Double = 0
    @Published var memoryUsedGB: Double = 0
    @Published var memoryTotalGB: Double = 0
    @Published var swapUsedGB: Double = 0
    @Published var swapTotalGB: Double = 0
    @Published var diskFreeGB: Double = 0
    @Published var diskTotalGB: Double = 0
    @Published var batteryPercent: Int? = nil
    @Published var isCharging: Bool = false
    @Published var uptime: String = ""
    @Published var thermalState: String = "Normal"
    @Published var topApps: [AppUsage] = []
    @Published var processCount: Int = 0
    @Published var macOSVersion: String = ""

    @Published var cpuHistory: [Double] = []
    @Published var gpuHistory: [Double] = []
    private let maxHistoryCount = 40

    private var previousCPUInfo: host_cpu_load_info?

    init() {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        macOSVersion = v.patchVersion > 0
            ? "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
            : "\(v.majorVersion).\(v.minorVersion)"
        updateMetrics()
    }

    func updateMetrics() {
        updateCPU()
        updateGPU()
        updateMemory()
        updateSwap()
        updateDisk()
        updateBattery()
        updateUptime()
        updateThermal()
        updateProcessCount()
        updateTopApps()
        cpuHistory.append(cpuUsage)
        gpuHistory.append(gpuUsage)
        if cpuHistory.count > maxHistoryCount { cpuHistory.removeFirst() }
        if gpuHistory.count > maxHistoryCount { gpuHistory.removeFirst() }
    }

    // No public API for system CPU %, host_statistics gives cumulative tick counts since boot to diff two samples over time to get % busy
    private func updateCPU() {
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }

        if let previous = previousCPUInfo {
            let userDiff = Double(cpuLoad.cpu_ticks.0 - previous.cpu_ticks.0)
            let sysDiff = Double(cpuLoad.cpu_ticks.1 - previous.cpu_ticks.1)
            let idleDiff = Double(cpuLoad.cpu_ticks.2 - previous.cpu_ticks.2)
            let niceDiff = Double(cpuLoad.cpu_ticks.3 - previous.cpu_ticks.3)
            let totalDiff = userDiff + sysDiff + idleDiff + niceDiff
            if totalDiff > 0 {
                cpuUsage = ((userDiff + sysDiff + niceDiff) / totalDiff) * 100
            }
        }
        previousCPUInfo = cpuLoad
    }

    // No public API for GPU %, IOAccelerator services expose an undocumented PerformanceStatistics dict. key name depends on GPU/driver, to check both
    private func updateGPU() {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(iterator) }

        var utilizations: [Double] = []
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            guard let props = IORegistryEntryCreateCFProperty(service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? [String: Any] else { continue }
            if let util = (props["Device Utilization %"] ?? props["GPU Activity(%)"]) as? Int {
                utilizations.append(Double(util))
            }
        }
        if let maxUtil = utilizations.max() {
            gpuUsage = maxUtil
        }
    }

    // Same mach API family as CPU. vm_statistics64 gives page counts by category; active+inactive+wired * page size is pretty much used memory
    private func updateMemory() {
        memoryTotalGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }

        let used = Double(stats.active_count + stats.inactive_count + stats.wire_count) * Double(vm_kernel_page_size)
        memoryUsedGB = used / 1_073_741_824.0
    }

    private func updateSwap() {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else { return }
        swapTotalGB = Double(usage.xsu_total) / 1_073_741_824.0
        swapUsedGB = Double(usage.xsu_used) / 1_073_741_824.0
    }

    private func updateDisk() {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let free = attrs[.systemFreeSize] as? NSNumber,
              let total = attrs[.systemSize] as? NSNumber else { return }
        diskFreeGB = free.doubleValue / 1_073_741_824.0
        diskTotalGB = total.doubleValue / 1_073_741_824.0
    }

    private func updateBattery() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any]
        else {
            batteryPercent = nil
            return
        }
        if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
            batteryPercent = capacity
        }
        if let state = description[kIOPSPowerSourceStateKey] as? String {
            isCharging = state == kIOPSACPowerValue
        }
    }

    private func updateUptime() {
        let seconds = Int(ProcessInfo.processInfo.systemUptime)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        uptime = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private func updateThermal() {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalState = "Normal"
        case .fair: thermalState = "Warm"
        case .serious: thermalState = "Hot"
        case .critical: thermalState = "Critical"
        @unknown default: thermalState = "Unknown"
        }
    }

    private func updateProcessCount() {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) == 0, size > 0 else { return }
        processCount = size / MemoryLayout<kinfo_proc>.stride
    }

    private func updateTopApps() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let pidToName = Dictionary(uniqueKeysWithValues: NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular }
                .map { ($0.processIdentifier, $0.localizedName ?? "Unknown") })
            guard !pidToName.isEmpty else { return }

            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/top")
            task.arguments = ["-l", "2", "-n", "50", "-stats", "pid,cpu"]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()

            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()
                guard let output = String(data: data, encoding: .utf8) else { return }

                let lines = output.components(separatedBy: "\n")
                guard let lastHeaderIndex = lines.lastIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("PID") }) else { return }

                var pidToCPU: [pid_t: Double] = [:]
                for line in lines[(lastHeaderIndex + 1)...] {
                    let parts = line.trimmingCharacters(in: .whitespaces).split(separator: " ")
                    guard parts.count == 2, let pid = pid_t(parts[0]), let cpu = Double(parts[1]) else { continue }
                    pidToCPU[pid] = cpu
                }

                let results = pidToName.compactMap { pid, name -> AppUsage? in
                    guard let cpu = pidToCPU[pid] else { return nil }
                    return AppUsage(name: name, cpuPercent: cpu)
                }
                .sorted { $0.cpuPercent > $1.cpuPercent }
                .prefix(3)

                DispatchQueue.main.async {
                    self?.topApps = Array(results)
                }
            } catch {
                // idk, ur mum
            }
        }
    }
}

struct LineGraph: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.1))

                if values.count > 1 {
                    let stepX = w / CGFloat(values.count - 1)
                    let points = values.enumerated().map { index, value in
                        CGPoint(x: CGFloat(index) * stepX, y: h - (CGFloat(min(max(value, 0), 100)) / 100 * h))
                    }

                    Path { path in
                        path.addLines(points)
                    }
                    .stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: h))
                        path.addLines(points)
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(tint.opacity(0.12))
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    private func rows(subviews: Subviews, maxWidth: CGFloat) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentWidth: CGFloat = 0

        for subview in subviews {
            let width = subview.sizeThatFits(.unspecified).width
            if currentWidth + width + spacing > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += width + spacing
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rowList = rows(subviews: subviews, maxWidth: maxWidth)
        let rowHeights = rowList.map { row in row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
        let totalHeight = rowHeights.reduce(0, +) + spacing * CGFloat(max(rowList.count - 1, 0))
        let totalWidth = rowList.map { row in row.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width + spacing } - spacing }.max() ?? 0
        return CGSize(width: maxWidth.isFinite ? maxWidth : totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
}

struct SystemStatsCard: View {
    @AppStorage("air_theme") private var theme: Theme = .light
    
    @StateObject private var monitor = SystemMonitor()
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("System")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.textColour)
                    Spacer()
                }

                VStack(spacing: 6) {
                    graphRow(icon: "cpu", label: "CPU", history: monitor.cpuHistory,
                             display: String(format: "%.0f%%", monitor.cpuUsage), tint: color(for: monitor.cpuUsage / 100))
                    graphRow(icon: "display", label: "GPU", history: monitor.gpuHistory,
                             display: String(format: "%.0f%%", monitor.gpuUsage), tint: color(for: monitor.gpuUsage / 100))
                }

                Divider().opacity(0)

                VStack(spacing: 10) {
                    metricBar(icon: "memorychip", label: "Memory",
                              value: monitor.memoryTotalGB > 0 ? monitor.memoryUsedGB / monitor.memoryTotalGB : 0,
                              display: String(format: "%.1f / %.1f GB", monitor.memoryUsedGB, monitor.memoryTotalGB))
                    metricBar(icon: "arrow.left.arrow.right.circle", label: "Swap",
                              value: monitor.swapTotalGB > 0 ? monitor.swapUsedGB / monitor.swapTotalGB : 0,
                              display: monitor.swapTotalGB > 0 ? String(format: "%.1f / %.1f GB", monitor.swapUsedGB, monitor.swapTotalGB) : "0.0 GB")
                    metricBar(icon: "internaldrive", label: "Disk",
                              value: monitor.diskTotalGB > 0 ? 1 - (monitor.diskFreeGB / monitor.diskTotalGB) : 0,
                              display: String(format: "%.0f GB free", monitor.diskFreeGB))
                }

                Divider().opacity(0)

                FlowLayout(spacing: 8) {
                    if let battery = monitor.batteryPercent {
                        pill(icon: monitor.isCharging ? "bolt.fill" : "battery.75", text: "\(battery)%")
                    }
                    pill(icon: "clock", text: monitor.uptime)
                    pill(icon: "thermometer.medium", text: monitor.thermalState)
                    pill(icon: "list.bullet", text: "\(monitor.processCount) procs")
                    pill(icon: "macwindow", text: "macOS \(monitor.macOSVersion)")
                }

                if !monitor.topApps.isEmpty {
                    Divider().opacity(0)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOP APPS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(theme.textColour)
                            .kerning(0.5)

                        ForEach(monitor.topApps) { app in
                            HStack {
                                Circle().fill(color(for: app.cpuPercent / 100)).frame(width: 5, height: 5)
                                Text(app.name)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.textColour)
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "%.0f%%", app.cpuPercent))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(theme.textColour)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .onReceive(timer) { _ in
                monitor.updateMetrics()
            }
        }
    }

    private func statHeader(icon: String, label: String, display: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(theme.textColour)
                .frame(width: 12)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.textColour)
            Spacer()
            Text(display)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textColour)
        }
    }

    private func metricBar(icon: String, label: String, value: Double, display: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            statHeader(icon: icon, label: label, display: display)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color(for: value))
                        .frame(width: max(3, geo.size.width * min(value, 1)))
                }
            }
            .frame(height: 4)
        }
    }

    private func graphRow(icon: String, label: String, history: [Double], display: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            statHeader(icon: icon, label: label, display: display)
            LineGraph(values: history, tint: tint)
                .frame(height: 20)
        }
    }

    private func pill(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(text).font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .foregroundColor(theme.textColour)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .fixedSize()
        .conditionalGlassEffect(in: Capsule())
    }

    private func color(for value: Double) -> Color {
        switch value {
        case ..<0.5: return .green
        case ..<0.8: return .orange
        default: return .red
        }
    }
}
