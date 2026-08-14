//
//  AudioManager.swift
//  air
//
//  Created by Dylan Karunanayake
//

import Foundation
internal import Combine
import AppKit

final class MediaRemoteBridge {
    static let shared = MediaRemoteBridge()

    private typealias SendCommandFunc = @convention(c) (Int, AnyObject?) -> Bool
    private var sendCommandFn: SendCommandFunc?
    
    private var isFetching = false
    private let fetchQueue = DispatchQueue(label: "com.air.nowplayingfetch", qos: .utility)

    private enum Command: Int {
        case play = 0
        case pause = 1
        case togglePlayPause = 2
        case nextTrack = 4
        case previousTrack = 5
    }

    private init() {
        if let bundle = Bundle(path: "/System/Library/PrivateFrameworks/MediaRemote.framework") {
            bundle.load()
        }

        let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW)
        if let handle = handle {
            if let sym = dlsym(handle, "MRMediaRemoteSendCommand") {
                sendCommandFn = unsafeBitCast(sym, to: SendCommandFunc.self)
            }
        }
    }

    func play() { _ = sendCommandFn?(Command.play.rawValue, nil) }
    func pause() { _ = sendCommandFn?(Command.pause.rawValue, nil) }
    func togglePlayPause() { _ = sendCommandFn?(Command.togglePlayPause.rawValue, nil) }
    func next() { _ = sendCommandFn?(Command.nextTrack.rawValue, nil) }
    func previous() { _ = sendCommandFn?(Command.previousTrack.rawValue, nil) }

    func fetchCLINowPlaying(completion: @escaping (TrackInfo?) -> Void) {
        fetchQueue.async { [weak self] in
            guard let self = self else { return }

            if self.isFetching { return }
            self.isFetching = true

            defer { self.isFetching = false }

            let bundledPath = Bundle.main.path(forResource: "nowplaying-cli", ofType: nil)
            let fallbackPaths = [
                bundledPath,
                "/opt/homebrew/bin/nowplaying-cli",
                "/usr/local/bin/nowplaying-cli"
            ].compactMap { $0 }

            guard let executablePath = fallbackPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let task = Process()
            let pipe = Pipe()

            task.executableURL = URL(fileURLWithPath: executablePath)
            task.arguments = ["get", "title", "artist", "playbackRate", "elapsedTime", "duration"]
            task.standardOutput = pipe

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    let lines = output.components(separatedBy: "\n")
                    if lines.count >= 5 {
                        let rawTitle = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let rawArtist = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        let rate = Double(lines[2].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                        let elapsed = Double(lines[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
                        let duration = Double(lines[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

                        let title = (rawTitle == "null" || rawTitle.isEmpty) ? "" : rawTitle
                        let artist = (rawArtist == "null" || rawArtist.isEmpty) ? "" : rawArtist

                        if !title.isEmpty {
                            let track = TrackInfo(
                                title: title,
                                artist: artist,
                                isPlaying: rate > 0,
                                position: elapsed,
                                duration: duration,
                                volume: 50
                            )
                            DispatchQueue.main.async { completion(track) }
                            return
                        }
                    }
                }
            } catch {
                print("nowplaying-cli Execution Error: \(error)")
            }

            DispatchQueue.main.async { completion(nil) }
        }
    }
}

enum AudioSourceKind: String, CaseIterable, Identifiable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case systemNowPlaying = "macOS Now Playing"

    var id: String { rawValue }

    var bundleIdentifier: String? {
        switch self {
        case .spotify: return "com.spotify.client"
        case .appleMusic: return "com.apple.Music"
        case .systemNowPlaying: return nil
        }
    }

    var appName: String? {
        switch self {
        case .spotify: return "Spotify"
        case .appleMusic: return "Music"
        case .systemNowPlaying: return nil
        }
    }

    var supportsScrubAndVolume: Bool {
        self != .systemNowPlaying
    }
}

struct TrackInfo: Equatable {
    var title: String = "Nothing Playing"
    var artist: String = ""
    var isPlaying: Bool = false
    var position: Double = 0
    var duration: Double = 0
    var volume: Double = 50
}

final class AudioSourceController: ObservableObject {
    @Published var track = TrackInfo()

    private var pollTimer: Timer?
    private var source: AudioSourceKind

    init(source: AudioSourceKind) {
        self.source = source
        startPolling()
    }

    func updateSource(_ newSource: AudioSourceKind) {
        source = newSource
        refresh()
    }

    func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        refresh()
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func ensureSourceIsPlaying() {
        switch source {
        case .spotify, .appleMusic:
            guard let bundleID = source.bundleIdentifier else { return }
            launchInBackgroundIfNeeded(bundleID: bundleID) { [weak self] in
                guard let self else { return }
                self.runAppleScript(self.script(for: .play))
                self.refresh()
            }
        case .systemNowPlaying:
            track.isPlaying = true
            MediaRemoteBridge.shared.play()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.refresh()
            }
        }
    }

    private func launchInBackgroundIfNeeded(bundleID: String, completion: @escaping () -> Void) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == bundleID && !$0.isTerminated }

        if isRunning {
            completion()
            return
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            completion()
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        config.hides = true

        if source == .spotify {
            config.arguments = ["--minimized"]
        }

        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
            if let error = error {
                print("Error booting background player: \(error)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                completion()
            }
        }
    }

    func togglePlayPause() {
        switch source {
        case .spotify, .appleMusic:
            track.isPlaying.toggle()
            runAppleScriptOffMainThread(script(for: .playPause))
        case .systemNowPlaying:
            track.isPlaying.toggle()
            MediaRemoteBridge.shared.togglePlayPause()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.refresh()
            }
        }
    }

    func next() {
        switch source {
        case .spotify, .appleMusic:
            runAppleScriptOffMainThread(script(for: .next))
        case .systemNowPlaying:
            MediaRemoteBridge.shared.next()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.refresh()
            }
        }
    }

    func previous() {
        switch source {
        case .spotify, .appleMusic:
            runAppleScriptOffMainThread(script(for: .previous))
        case .systemNowPlaying:
            MediaRemoteBridge.shared.previous()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.refresh()
            }
        }
    }

    func seek(to seconds: Double) {
        guard source.supportsScrubAndVolume else { return }
        runAppleScriptOffMainThread(script(for: .seek(seconds)))
    }

    func setVolume(_ percent: Double) {
        guard source.supportsScrubAndVolume else { return }
        runAppleScriptOffMainThread(script(for: .setVolume(Int(percent))))
    }

    private func runAppleScriptOffMainThread(_ sourceStr: String?) {
        guard let sourceStr else { return }

        guard let bundleID = source.bundleIdentifier else {
            executeScriptOffMainThread(sourceStr)
            return
        }

        launchInBackgroundIfNeeded(bundleID: bundleID) { [weak self] in
            self?.executeScriptOffMainThread(sourceStr)
        }
    }

    private func executeScriptOffMainThread(_ sourceStr: String) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.runAppleScript(sourceStr)
            DispatchQueue.main.async {
                self?.refresh()
            }
        }
    }

    private func refresh() {
        switch source {
        case .spotify, .appleMusic:
            guard let script = script(for: .state) else { return }
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let self else { return }
                guard let result = self.runAppleScript(script) else { return }
                let parsed = self.parseState(result.stringValue)
                DispatchQueue.main.async { self.track = parsed }
            }
        case .systemNowPlaying:
            MediaRemoteBridge.shared.fetchCLINowPlaying { [weak self] cliTrack in
                guard let self = self, self.source == .systemNowPlaying else { return }
                if let cliTrack = cliTrack {
                    self.track = cliTrack
                }
            }
        }
    }

    private func parseState(_ raw: String?) -> TrackInfo {
        guard let raw else { return TrackInfo() }
        let parts = raw.components(separatedBy: "|")
        guard parts.count == 6 else { return TrackInfo() }

        return TrackInfo(
            title: parts[1].isEmpty ? "Nothing Playing" : parts[1],
            artist: parts[2],
            isPlaying: parts[0] == "playing",
            position: Double(parts[3]) ?? 0,
            duration: Double(parts[4]) ?? 0,
            volume: Double(parts[5]) ?? 50
        )
    }

    @discardableResult
    private func runAppleScript(_ source: String?) -> NSAppleEventDescriptor? {
        guard let source else { return nil }
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)
        return result
    }

    private enum Command {
        case play
        case playPause
        case next
        case previous
        case seek(Double)
        case setVolume(Int)
        case state
    }

    private func script(for command: Command) -> String? {
        let appName: String
        switch source {
        case .spotify: appName = "Spotify"
        case .appleMusic: appName = "Music"
        case .systemNowPlaying: return nil
        }

        switch command {
        case .play:
            return "tell application \"\(appName)\" to play"
        case .playPause:
            return "tell application \"\(appName)\" to playpause"
        case .next:
            return "tell application \"\(appName)\" to next track"
        case .previous:
            return "tell application \"\(appName)\" to previous track"
        case .seek(let seconds):
            return "tell application \"\(appName)\" to set player position to \(seconds)"
        case .setVolume(let percent):
            return "tell application \"\(appName)\" to set sound volume to \(percent)"
        case .state:
            if source == .spotify {
                return """
                tell application "Spotify"
                    if it is running then
                        set playerState to (player state as string)
                        set trackName to ""
                        set trackArtist to ""
                        set pos to 0
                        set dur to 0
                        try
                            set trackName to name of current track
                            set trackArtist to artist of current track
                            set pos to player position
                            set dur to (duration of current track) / 1000
                        end try
                        set vol to sound volume
                        return playerState & "|" & trackName & "|" & trackArtist & "|" & pos & "|" & dur & "|" & vol
                    else
                        return "stopped||||0|0|50"
                    end if
                end tell
                """
            } else {
                return """
                tell application "Music"
                    if it is running then
                        set playerState to (player state as string)
                        set trackName to ""
                        set trackArtist to ""
                        set dur to 0
                        set pos to player position
                        try
                            set trackName to name of current track
                            set trackArtist to artist of current track
                            set dur to duration of current track
                        end try
                        set vol to sound volume
                        return playerState & "|" & trackName & "|" & trackArtist & "|" & pos & "|" & dur & "|" & vol
                    else
                        return "stopped||||0|0|50"
                    end if
                end tell
                """
            }
        }
    }
}
