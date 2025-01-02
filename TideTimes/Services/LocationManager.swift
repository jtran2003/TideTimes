import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    @Published var locations: [Location] = []
    @Published var searchError: Error?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func searchLocations(_ query: String) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.locations = []
            }
            return
        }
        
        print("Searching for: \(query)") // Debug print
        
        // Cancel any previous geocoding request
        geocoder.cancelGeocode()
        
        // Search for locations matching the query
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)") // Debug print
                    self?.searchError = error
                    self?.locations = []
                    return
                }
                
                guard let placemarks = placemarks else {
                    self?.locations = []
                    return
                }
                
                let newLocations = placemarks.compactMap { placemark -> Location? in
                    guard let name = placemark.name ?? placemark.locality ?? placemark.administrativeArea,
                          let location = placemark.location else { return nil }
                    
                    // Create a more detailed name including city/state if available
                    var fullName = name
                    if let locality = placemark.locality, !name.contains(locality) {
                        fullName += ", \(locality)"
                    }
                    if let adminArea = placemark.administrativeArea, !name.contains(adminArea) {
                        fullName += ", \(adminArea)"
                    }
                    
                    return Location(
                        id: "\(location.coordinate.latitude),\(location.coordinate.longitude)",
                        name: fullName,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                }
                
                print("Found \(newLocations.count) locations") // Debug print
                self?.locations = newLocations
            }
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location access granted") // Debug print
                manager.startUpdatingLocation()
            default:
                print("Location access not granted: \(manager.authorizationStatus)") // Debug print
                manager.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle current location updates if needed
        print("Location updated") // Debug print
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("Location manager error: \(error.localizedDescription)") // Debug print
            self.searchError = error
        }
    }
} 