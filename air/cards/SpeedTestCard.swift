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
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView("Testing speed...")
                } else if let downloadSpeed = viewModel.downloadSpeed {
                    if let uploadSpeed = viewModel.uploadSpeed {
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.square")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(String(format: "%.1f", downloadSpeed))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.middark)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    Text("Mbps")
                                        .font(.caption)
                                        .foregroundColor(.middark)
                                }
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.square")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(String(format: "%.1f", uploadSpeed))
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.middark)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    Text("Mbps")
                                        .font(.caption)
                                        .foregroundColor(.middark)
                                }
                            }
                        }
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
