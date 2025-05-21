//
//  AppStorageManager.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 21.05.2025.
//

import Foundation

final class AppStorageManager {
    static let shared = AppStorageManager()
    
    private init() {}

    func save(data: Any, forKey key: String) {
        UserDefaults.standard.set(data, forKey: key)
    }

    func get(forKey key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }

    func remove(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
