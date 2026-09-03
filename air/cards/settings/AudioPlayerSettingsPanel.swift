//
//  AudioPlayerSettingsView.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct AudioPlayerSettingsPanel: View {
    @AppStorage("audio_player_source") private var audioSourceRaw: String = AudioSourceSetting.spotify.rawValue
    @AppStorage("audio_show_artwork") private var showArtwork: Bool = true

    private var audioSource: AudioSourceSetting {
        AudioSourceSetting(rawValue: audioSourceRaw) ?? .spotify
    }

    var body: some View {
        SettingsPanel(name: "Audio Player") {
            Section {
                Picker("Audio Source", selection: Binding(
                    get: { audioSource },
                    set: { audioSourceRaw = $0.rawValue }
                )) {
                    ForEach(AudioSourceSetting.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Source")
            } footer: {
                footerText
            }
            
            Section {
                Toggle("Show Artwork", isOn: $showArtwork)
            } header : {
                Text("Detials")
            }
        }
    }

    private var footerText: some View {
        Group {
            switch audioSource {
            case .spotify:
                Text("air will open Spotify and resume your most recently played queue.")
            case .appleMusic:
                Text("air will open Music and resume your most recently played music.")
            case .systemNowPlaying:
                Text("air will control whatever app currently owns the system media session, for example a browser tab playing YouTube.")
            }
        }
        .font(.system(size: 11))
    }
}
