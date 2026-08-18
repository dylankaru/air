//
//  SpeedTestCard.swift
//  air
//
//  Created by Dylan Karunanayake on 17/8/2026.
//

import SwiftUI

struct SpeedTestCard: View {
    @State private var viewModel = SpeedTestViewModel()

    var body: some View {
        Card {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Testing speed...")
                } else if let speed = viewModel.downloadSpeed {
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", speed))
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.middark)
                        Text("Mbps")
                            .font(.caption)
                            .foregroundColor(.middark)
                    }
                } else {
                    Text("Ready to test network speed")
                        .foregroundColor(.secondary)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .task{
            await viewModel.startTest()
        }
    }
}
