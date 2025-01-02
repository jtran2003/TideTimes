import Foundation

struct Location: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // We can keep the existing Equatable implementation
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
}

struct TideData: Codable, Identifiable {
    let time: Date
    let height: Double
    let type: TideType
    
    enum TideType: String, Codable {
        case high
        case low
        case current
    }
    
    var id: Date { time }
    
    // Custom initializer for creating instances in code
    init(time: Date, height: Double, type: TideType) {
        self.time = time
        self.height = height
        self.type = type
    }
} 
