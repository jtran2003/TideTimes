import Foundation

enum ConfigurationError: Error {
    case missingKey(String)
    case invalidPlistFile
}

class ConfigurationManager {
    static let shared = ConfigurationManager()
    private var config: [String: Any]
    
    private init() {
        guard let plistPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plistDict = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            config = [:]
            return
        }
        
        config = plistDict
    }
    
    func string(for key: String) throws -> String {
        guard let value = config[key] as? String else {
            throw ConfigurationError.missingKey(key)
        }
        return value
    }
} 