//
//  SpacesManager.swift
//  air
//
//  Created by Dylan Karunanayake on 22/9/2026.
//

import SwiftUI
internal import Combine

struct SpaceDTO: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var desc: String?
    var image: String?
    var theme: Theme
    var cardKeys: [String]
}

struct CardSpace: Identifiable {
    let id: UUID
    var name: String
    var desc: String?
    var image: String?
    var theme: Theme
    var cardList: [CardItem]
}

class SpacesManager: ObservableObject {
    static let shared = SpacesManager()
    
    private static let requiredCardKey = "greeting"
    
    @Published var spaces: [CardSpace] = []
    private let filename = "air_spaces.json"
    
    private init() {
        load()
        if spaces.isEmpty {
            spaces = [CardSpace(id: UUID(), name: "Home", desc: nil, image: nil, theme: .light, cardList: appCards)]
            save()
        }
    }
    
    private func resolveCards(_ cardKeys: [String]) -> [CardItem] {
        var keys = cardKeys
        if !keys.contains(Self.requiredCardKey) {
            keys.insert(Self.requiredCardKey, at: 0)
        }
        return keys.compactMap { key in appCards.first { $0.key == key } }
    }
    
    func addSpace(name: String, desc: String? = nil, image: String? = nil, theme: Theme = .light, cardKeys: [String]) {
        spaces.append(CardSpace(id: UUID(), name: name, desc: desc, image: image, theme: theme, cardList: resolveCards(cardKeys)))
        save()
    }
    
    func deleteSpace(id: UUID) {
        guard spaces.count > 1 else { return }
        spaces.removeAll { $0.id == id }
        save()
    }
    
    func renameSpace(id: UUID, to newName: String) {
        guard let idx = spaces.firstIndex(where: { $0.id == id }) else { return }
        spaces[idx].name = newName
        save()
    }
    
    func setTheme(_ theme: Theme, for id: UUID) {
        guard let idx = spaces.firstIndex(where: { $0.id == id }) else { return }
        spaces[idx].theme = theme
        save()
    }
    
    func setCardKeys(_ cardKeys: [String], for id: UUID) {
        guard let idx = spaces.firstIndex(where: { $0.id == id }) else { return }
        spaces[idx].cardList = resolveCards(cardKeys)
        save()
    }
    
    private func load() {
        guard let dtos = JSONManager.load([SpaceDTO].self, from: filename, location: .applicationSupport) else { return }
        spaces = dtos.map { dto in
            CardSpace(id: dto.id, name: dto.name, desc: dto.desc, image: dto.image, theme: dto.theme, cardList: resolveCards(dto.cardKeys))
        }
    }
    
    private func save() {
        let dtos = spaces.map {
            SpaceDTO(id: $0.id, name: $0.name, desc: $0.desc, image: $0.image, theme: $0.theme, cardKeys: $0.cardList.map(\.key))
        }
        try? JSONManager.save(dtos, to: filename, location: .applicationSupport)
    }
}
