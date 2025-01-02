import Combine
import Foundation

enum TideServiceError: LocalizedError {
    case invalidLocation
    case serverError(Int)
    case noData
    case invalidResponse
    case decodingError(String)
    case noTidalData
    
    var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Unable to get tide data for this location."
        case .serverError(let code):
            return "Server error (code: \(code)). Please try again later."
        case .noData:
            return "No tide data available for this location."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .decodingError(let message):
            return "Error processing tide data: \(message)"
        case .noTidalData:
            return "There is no tide data here"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .noTidalData:
            return "Try searching for a location closer to the coast"
        default:
            return nil
        }
    }
    
    var isNoTidalData: Bool {
        if case .noTidalData = self { return true }
        return false
    }
}

class TideService {
    private let apiKey: String
    private let baseURL = "https://www.worldtides.info/api/v3"
    
    init() {
        // Use a default API key if Config.plist is not set up
        do {
            apiKey = try ConfigurationManager.shared.string(for: "WorldTidesAPIKey")
        } catch {
            print("Warning: Using default API key. Please set up Config.plist")
            apiKey = "YOUR_DEFAULT_KEY"
        }
    }
    
    func getTideData(for location: Location) -> AnyPublisher<[TideData], Error> {
        let calendar = Calendar.current
        let now = Date()
        let start = Int(calendar.date(byAdding: .hour, value: -24, to: now)!.timeIntervalSince1970)
        let end = Int(calendar.date(byAdding: .hour, value: 24, to: now)!.timeIntervalSince1970)
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "extremes", value: ""),
            URLQueryItem(name: "heights", value: ""),
            URLQueryItem(name: "datum", value: "LAT"),
            URLQueryItem(name: "lat", value: String(location.latitude)),
            URLQueryItem(name: "lon", value: String(location.longitude)),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "end", value: String(end)),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        print("Fetching tide data from: \(url)") // Debug print
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("Response status code: \(httpResponse.statusCode)") // Debug print
                
                if httpResponse.statusCode != 200 {
                    let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                    print("Error response: \(responseString)")
                    
                    // Check for specific error codes
                    if httpResponse.statusCode == 400 || 
                       responseString.contains("out of range") || 
                       responseString.contains("no tide data") {
                        throw TideServiceError.noTidalData
                    }
                    
                    throw TideServiceError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: WorldTidesResponse.self, decoder: JSONDecoder())
            .tryMap { response -> [TideData] in
                var tideData: [TideData] = []
                
                // Add extremes (high and low tides)
                tideData.append(contentsOf: response.extremes.map { extreme in
                    TideData(
                        time: Date(timeIntervalSince1970: TimeInterval(extreme.dt)),
                        height: extreme.height,
                        type: extreme.type == "High" ? .high : .low
                    )
                })
                
                // Add current height
                if let currentHeight = response.heights.first {
                    tideData.append(
                        TideData(
                            time: Date(timeIntervalSince1970: TimeInterval(currentHeight.dt)),
                            height: currentHeight.height,
                            type: .current
                        )
                    )
                }
                
                return tideData.sorted { $0.time < $1.time }
            }
            .mapError { error -> Error in
                print("Error in tide data pipeline: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    return TideServiceError.decodingError(decodingError.localizedDescription)
                }
                return error
            }
            .eraseToAnyPublisher()
    }
}

// WorldTides API Response Models
private struct WorldTidesResponse: Codable {
    let status: Int
    let extremes: [Extreme]
    let heights: [Height]
}

private struct Extreme: Codable {
    let dt: Int
    let height: Double
    let type: String
}

private struct Height: Codable {
    let dt: Int
    let height: Double
}
