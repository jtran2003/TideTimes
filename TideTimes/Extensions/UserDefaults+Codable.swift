import Foundation

extension UserDefaults {
    func encode<T: Encodable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else { return }
        set(data, forKey: key)
    }
    
    func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
} 