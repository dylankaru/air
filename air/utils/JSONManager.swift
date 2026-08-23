//
//  JSONManager.swift
//  air
//
//  Created by Dylan Karunanayake on 22/8/2026.
//

import Foundation

enum StorageLocation {
    case applicationSupport
    case cache
    
    var url: URL {
        let fm = FileManager.default
        let search: FileManager.SearchPathDirectory = (self == .applicationSupport) ? .applicationSupportDirectory : .cachesDirectory
        let baseURL = fm.urls(for: search, in: .userDomainMask).first!
        let bundleID = Bundle.main.bundleIdentifier ?? "air"
        let targetDir = baseURL.appending(path: bundleID, directoryHint: .isDirectory)
        
        if !fm.fileExists(atPath: targetDir.path) {
            try? fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }
        return targetDir
    }
}

enum JSONManager {
    static func save<T: Encodable>(_ item: T, to filename: String, location: StorageLocation = .applicationSupport, encoder: JSONEncoder = JSONEncoder()) throws {
        let fileURL = location.url.appending(path: filename)
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(item)
        try data.write(to: fileURL, options: .atomic)
    }
    
    static func load<T: Decodable>(_ type: T.Type, from filename: String,location: StorageLocation = .applicationSupport) -> T? {
            let fileURL = location.url.appending(path: filename)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            
            do {
                let data = try Data(contentsOf: fileURL)
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("Failed to decode \(filename): \(error)")
                return nil
            }
        }
    
    static func delete(_ filename: String, location: StorageLocation = .applicationSupport) throws {
        let fileURL = location.url.appending(path: filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    static func exists(_ filename: String, location: StorageLocation = .applicationSupport) -> Bool {
        let fileURL = location.url.appending(path: filename)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
