import SwiftUI
import Combine

class TideViewModel: ObservableObject {
    @Published var currentLocation: Location?
    @Published var tideData: [TideData] = []
    @Published var error: Error?
    @Published var isLoading = false
    @Published var recentLocations: [Location]?
    @Published var favoriteLocations: Set<Location> = []
    
    private let tideService: TideService
    private let locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(tideService: TideService = TideService(), 
         locationManager: LocationManager = LocationManager()) {
        self.tideService = tideService
        self.locationManager = locationManager
        loadFavorites()
        loadRecentLocations()
    }
    
    func setLocation(_ location: Location) {
        currentLocation = location
        UserDefaults.standard.encode(location, forKey: "savedLocation")
        addToRecentLocations(location)
        fetchTideData()
    }
    
    func toggleFavorite(_ location: Location) {
        if favoriteLocations.contains(location) {
            favoriteLocations.remove(location)
        } else {
            favoriteLocations.insert(location)
        }
        saveFavorites()
    }
    
    func isFavorite(_ location: Location) -> Bool {
        favoriteLocations.contains(location)
    }
    
    private func addToRecentLocations(_ location: Location) {
        var recent = recentLocations ?? []
        if let index = recent.firstIndex(where: { $0.id == location.id }) {
            recent.remove(at: index)
        }
        recent.insert(location, at: 0)
        if recent.count > 5 { // Keep only last 5 locations
            recent = Array(recent.prefix(5))
        }
        recentLocations = recent
        UserDefaults.standard.encode(recent, forKey: "recentLocations")
    }
    
    private func loadRecentLocations() {
        recentLocations = UserDefaults.standard.decode([Location].self, forKey: "recentLocations")
    }
    
    private func saveFavorites() {
        UserDefaults.standard.encode(Array(favoriteLocations), forKey: "favoriteLocations")
    }
    
    private func loadFavorites() {
        if let favorites: [Location] = UserDefaults.standard.decode([Location].self, forKey: "favoriteLocations") {
            favoriteLocations = Set(favorites)
        }
    }
    
    func loadSavedLocation() {
        if let savedLocation: Location = UserDefaults.standard.decode(Location.self, forKey: "savedLocation") {
            print("Loading saved location: \(savedLocation.name)") // Debug print
            currentLocation = savedLocation
            fetchTideData()
        }
    }
    
    private func fetchTideData() {
        guard let location = currentLocation else { return }
        
        print("Fetching tide data for: \(location.name)") // Debug print
        isLoading = true
        error = nil
        tideData = [] // Clear existing data
        
        tideService.getTideData(for: location)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("Error fetching tide data: \(error.localizedDescription)") // Debug print
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] tideData in
                    print("Received \(tideData.count) tide data points") // Debug print
                    self?.tideData = tideData
                }
            )
            .store(in: &cancellables)
    }
} 
