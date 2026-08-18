//
//  APIDownloadRequest.swift
//  air
//
//  Created by Dylan Karunanayake on 18/8/2026.
//

import SwiftUI
import Foundation

@MainActor
@Observable
final class SpeedTestViewModel {
    var downloadSpeed: Double?
    var isLoading = false
    var errorMessage: String?

    func startTest() async {
        isLoading = true
        errorMessage = nil
        downloadSpeed = nil
        
        do {
            downloadSpeed = try await runSpeedTest()
        } catch {
            errorMessage = "Test failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    private func runSpeedTest() async throws -> Double {
        guard let url = URL(string: "https://airapi.destinyorg.com.au/download?size_mb=40") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let startTime = Date()
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Server responded with status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let serverMessage = String(data: data, encoding: .utf8) {
                    print("Server error message: \(serverMessage)")
                }
                throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
            }
        }
        
        print("Downloaded \(data.count) bytes.")
        
        if data.isEmpty {
            throw URLError(.zeroByteResource)
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let megabits = Double(data.count) * 8.0 / 1_000_000.0
        
        return megabits / elapsedTime
    }
}
