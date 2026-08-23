//
//  APISpeedRequest.swift
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
    var uploadSpeed: Double?
    var isLoading = false
    var errorMessage: String?

    func startTest() async {
        isLoading = true
        errorMessage = nil
        downloadSpeed = nil
        
        do {
            downloadSpeed = try await runDownloadSpeedTest()
            uploadSpeed = try await runUploadSpeedTest()
        } catch {
            errorMessage = "Test failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    private func runDownloadSpeedTest() async throws -> Double {
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
    
    private func runUploadSpeedTest(sizeMB: Int = 20) async throws -> Double {
        guard let url = URL(string: "https://airapi.destinyorg.com.au/upload") else {
            throw URLError(.badURL)
        }
        
        let byteCount = sizeMB * 1024 * 1024
        let payload = Data(count: byteCount)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: payload)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Upload server responded with status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let serverMessage = String(data: data, encoding: .utf8) {
                    print("Upload server error message: \(serverMessage)")
                }
                throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
            }
        }
        
        guard duration > 0 else { return 0.0 }
        let megabitsSent = (Double(byteCount) * 8.0) / 1_000_000.0
        return (megabitsSent / duration)
    }
}
