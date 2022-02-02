//
//  StorageManager.swift
//  Dataforbruk
//
//  Created by Eskil Sviggum on 01/02/2022.
//

import Foundation

class StorageManager {
    let ud = UserDefaults(suiteName: "group.com.skillbreak.Dataforbruk") ?? UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func store<T:Codable>(data: T, withKey key: String) {
        guard let data = try? encoder.encode(data) else { return }
        ud.setValue(data, forKey: key)
    }
    
    func retrieveData<T:Codable>(withKey key: String) -> T? {
        guard let data = ud.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
    
    func removeData(withKey key: String) {
        ud.removeObject(forKey: key)
    }
}

struct StorageKeys {
    static let usageResult = "USAGE_RESULT"
    static let lastUpdate = "LAST_UPDATE"
}
