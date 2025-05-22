//
//  AppStorageManager.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 21.05.2025.
//

import Foundation

final class AppStorageManager {
    static let shared = AppStorageManager()
    private let defaults = UserDefaults.standard
    private init() {}

    func save<T: Codable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    func get<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return decoded
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
