//
//  AudioSourceKind.swift
//  air
//
//  Created by Dylan Karunanayake on 14/8/2026.
//


//
//  AudioSourceController.swift
//  air
//
//  Created by Dylan Karunanayake on 13/8/2026.
//

import Foundation
import AppKit

// MARK: - Media key constants (from IOKit/hidsystem/ev_keymap.h)
// Not bridged into Swift by default, so we define the values we need directly.
private let NX_KEYTYPE_PLAY: Int32 = 16
private let NX_KEYTYPE_NEXT: Int32 = 17
private let NX_KEYTYPE_PREVIOUS: Int32 = 18

enum AudioSourceKind: String, CaseIterable, Identifiable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case other = "Other"

    var id: String { rawValue }

    /// The AppleScript application name used in `tell application "___"`.
    var scriptingAppName: String? {
        switch self {
        case .spotify: return "Spotify"
        case .appleMusic: return "Music"
        case .other: return nil
        }
    }

    var bundleIdentifier: String? {
        switch self {
        case .spotify: return "com.spotify.client"
        case .appleMusic: return "com.apple.Music"
        case .other: return nil
        }
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

/// Drives whichever audio source is configured in Settings. For Spotify/Apple Music this
/// uses AppleScript, which is able to launch the app in the background and resume whatever
/// it last had queued — no extra work needed, that's just how those apps behave when told
/// to play. For anything else, we fall back to a system media-key event since there's no
/// generic way to script an arbitrary, unknown app.
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

    // MARK: - Lifecycle

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

    // MARK: - Ensuring the source is running & playing, with zero friction

    /// Launches the configured app in the background if it isn't already running, then
    /// tells it to play. Spotify/Music resume their own last session automatically — we
    /// don't need to know or set the playlist ourselves.
    func ensureSourceIsPlaying() {
        switch source {
        case .spotify, .appleMusic:
            guard let bundleID = source.bundleIdentifier else { return }
            launchInBackgroundIfNeeded(bundleID: bundleID) { [weak self] in
                guard let self else { return }
                self.runAppleScript(self.script(for: .play))
                self.refresh()
            }
        case .other:
            // We don't know which app to launch, so the best we can do is nudge
            // whatever currently owns the system Now Playing session.
            sendMediaKey(NX_KEYTYPE_PLAY)
        }
    }

    private func launchInBackgroundIfNeeded(bundleID: String, completion: @escaping () -> Void) {
        let alreadyRunning = NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == bundleID }

        if alreadyRunning {
            completion()
            return
        }

        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            // App isn't installed — nothing we can do.
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = false // keep it backgrounded, don't steal focus
        config.hides = true

        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            // Give the app a moment to finish launching before we script it.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                completion()
            }
        }
    }

    // MARK: - Transport controls

    func togglePlayPause() {
        switch source {
        case .spotify, .appleMusic:
            runAppleScript(script(for: .playPause))
        case .other:
            sendMediaKey(NX_KEYTYPE_PLAY)
        }
        refresh()
    }

    func next() {
        switch source {
        case .spotify, .appleMusic:
            runAppleScript(script(for: .next))
        case .other:
            sendMediaKey(NX_KEYTYPE_NEXT)
        }
        refresh()
    }

    func previous() {
        switch source {
        case .spotify, .appleMusic:
            runAppleScript(script(for: .previous))
        case .other:
            sendMediaKey(NX_KEYTYPE_PREVIOUS)
        }
        refresh()
    }

    func seek(to seconds: Double) {
        guard source != .other else { return }
        runAppleScript(script(for: .seek(seconds)))
        refresh()
    }

    func setVolume(_ percent: Double) {
        guard source != .other else { return }
        runAppleScript(script(for: .setVolume(Int(percent))))
    }

    // MARK: - Polling / state read

    private func refresh() {
        guard source != .other, let script = script(for: .state) else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            guard let result = self.runAppleScript(script) else { return }
            let parsed = self.parseState(result)
            DispatchQueue.main.async {
                self.track = parsed
            }
        }
    }

    private func parseState(_ descriptor: NSAppleEventDescriptor) -> TrackInfo {
        // AppleScript hands back a "|"-delimited string:
        // playerState|title|artist|position|duration|volume
        guard let raw = descriptor.stringValue else { return TrackInfo() }
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

    // MARK: - AppleScript plumbing

    @discardableResult
    private func runAppleScript(_ source: String?) -> NSAppleEventDescriptor? {
        guard let source else { return nil }
        var error: NSDictionary?
        let script = NSAppleScript(source: source)
        let result = script?.executeAndReturnError(&error)
        if let error {
            print("AudioSourceController AppleScript error: \(error)")
        }
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
        guard let appName = source.scriptingAppName else { return nil }

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
            switch source {
            case .spotify:
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
            case .appleMusic:
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
            case .other:
                return nil
            }
        }
    }

    // MARK: - Media key fallback (used only for "Other")

    private func sendMediaKey(_ key: Int32) {
        func post(_ isKeyDown: Bool) {
            let flags: NSEvent.ModifierFlags = isKeyDown ? NSEvent.ModifierFlags(rawValue: 0xa00) : NSEvent.ModifierFlags(rawValue: 0xb00)
            let data1 = Int((key << 16) | (isKeyDown ? 0xa00 : 0xb00) | ((isKeyDown ? 0xa : 0xb) << 8))
            guard let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            ), let cgEvent = event.cgEvent else { return }
            cgEvent.post(tap: .cghidEventTap)
        }
        post(true)
        post(false)
    }
}