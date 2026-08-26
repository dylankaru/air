//
//  AudioPlayerCard.swift
//  air
//
//  Created by Dylan Karunanayake on 13/8/2026.
//

import SwiftUI

enum AudioSourceSetting: String, CaseIterable, Identifiable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case systemNowPlaying = "System"

    var id: String { rawValue }

    var kind: AudioSourceKind {
        switch self {
        case .spotify: return .spotify
        case .appleMusic: return .appleMusic
        case .systemNowPlaying: return .systemNowPlaying
        }
    }
}

struct AudioPlayerCard: View {
    @AppStorage("audio_player_source") private var audioSourceRaw: String = AudioSourceSetting.spotify.rawValue
    @AppStorage("audio_show_artwork") private var showArtwork: Bool = true
    @AppStorage("air_theme") private var theme: Theme = .light

    @StateObject private var controller: AudioSourceController

    @State private var isScrubbingPosition = false
    @State private var scrubPosition: Double = 0
    @State private var volume: Double = 50
    @State private var hasKickedOffPlayback = false

    private var audioSource: AudioSourceSetting {
        AudioSourceSetting(rawValue: audioSourceRaw) ?? .spotify
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "audio_player_source") ?? AudioSourceSetting.spotify.rawValue
        let kind = (AudioSourceSetting(rawValue: raw) ?? .spotify).kind
        _controller = StateObject(wrappedValue: AudioSourceController(source: kind))
    }

    var body: some View {
        Card {
            VStack {
                Spacer(minLength: 0)
                
                VStack(spacing: audioSource == .systemNowPlaying ? 16 : 8) {
                    trackInfo
                    if audioSource != .systemNowPlaying {
                        progressBar
                    }
                    transportControls
                    if audioSource != .systemNowPlaying {
                        volumeBar
                    }
                    switchSource
                }
                
                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .tint(theme.textColour)
        .foregroundColor(theme.textColour)
        .onAppear {
            volume = controller.track.volume
            if !hasKickedOffPlayback {
                hasKickedOffPlayback = true
                controller.ensureSourceIsPlaying()
            }
        }
        .onChange(of: audioSourceRaw) { _, newValue in
            let kind = (AudioSourceSetting(rawValue: newValue) ?? .spotify).kind
            controller.updateSource(kind)
            controller.ensureSourceIsPlaying()
        }
        .onChange(of: controller.track.volume) { _, newValue in
            if !isScrubbingPosition {
                volume = newValue
            }
        }
    }

    private var displayTitle: String {
        let title = controller.track.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty || title.lowercased() == "nothing playing" {
            return "Click the player to resume your session"
        }
        return title
    }

    private var displayArtist: String {
        let artist = controller.track.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        if artist.isEmpty || artist.lowercased() == "unknown artist" {
            return "Standing by"
        }
        return artist
    }

    private var trackInfo: some View {
        HStack(spacing: 12) {
            if showArtwork {
                artworkView
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.system(size: audioSource == .systemNowPlaying ? 16 : 13, weight: audioSource == .systemNowPlaying ? .bold : .semibold))
                    .foregroundColor(theme.textColour)
                    .lineLimit(1)
                
                Text(displayArtist)
                    .font(.system(size: audioSource == .systemNowPlaying ? 13 : 11, weight: .medium))
                    .foregroundColor(theme.textColour.opacity(0.75))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }

    private var artworkView: some View {
        Group {
            if let artwork = controller.track.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.textColour.opacity(0.1))
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(theme.textColour.opacity(0.5))
                }
            }
        }
        .frame(width: audioSource == .systemNowPlaying ? 52 : 44, height: audioSource == .systemNowPlaying ? 52 : 44)
        .cornerRadius(8)
        .clipped()
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { isScrubbingPosition ? scrubPosition : controller.track.position },
                    set: { newValue in
                        isScrubbingPosition = true
                        scrubPosition = newValue
                    }
                ),
                in: 0...(max(controller.track.duration, 1)),
                onEditingChanged: { editing in
                    if !editing {
                        controller.seek(to: scrubPosition)
                        isScrubbingPosition = false
                    }
                }
            )
            .controlSize(.small)
            .tint(theme.textColour)
            .disabled(!audioSource.kind.supportsScrubAndVolume)

            HStack {
                Text(formatTime(isScrubbingPosition ? scrubPosition : controller.track.position))
                Spacer()
                Text(formatTime(controller.track.duration))
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(theme.textColour.opacity(0.6))
        }
    }

    private var transportControls: some View {
        let isSystem = audioSource == .systemNowPlaying
        
        return HStack(spacing: 24) {
            Button {
                controller.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: isSystem ? 15 : 13))
            }

            Button {
                controller.togglePlayPause()
            } label: {
                Image(systemName: controller.track.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: isSystem ? 22 : 18, weight: .semibold))
                    .frame(width: isSystem ? 30 : 28, height: isSystem ? 30 : 28)
            }

            Button {
                controller.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: isSystem ? 15 : 13))
            }
        }
        .frame(maxWidth: .infinity, alignment: isSystem ? .leading : .center)
        .buttonStyle(.plain)
        .foregroundColor(theme.textColour)
    }

    private var volumeBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 9))
                .foregroundColor(theme.textColour.opacity(0.6))
            
            Slider(
                value: $volume,
                in: 0...100,
                onEditingChanged: { editing in
                    if !editing {
                        controller.setVolume(volume)
                    }
                }
            )
            .controlSize(.small)
            .tint(theme.textColour)
            .disabled(!audioSource.kind.supportsScrubAndVolume)
            
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 9))
                .foregroundColor(theme.textColour.opacity(0.6))
        }
    }
    
    private var switchSource: some View {
        Button {
            let allSources = AudioSourceSetting.allCases
            if let currentIndex = allSources.firstIndex(of: audioSource) {
                let nextIndex = (currentIndex + 1) % allSources.count
                audioSourceRaw = allSources[nextIndex].rawValue
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: audioSource == .systemNowPlaying ? 13 : 12, weight: .medium))
                .foregroundColor(theme.textColour.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(.plain)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
