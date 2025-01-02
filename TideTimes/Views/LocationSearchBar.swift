import SwiftUI
import Combine
import CoreLocation

struct LocationSearchBar: View {
    @Binding var text: String
    let onLocationSelected: (Location) -> Void
    
    @StateObject private var locationManager = LocationManager()
    @State private var isEditing = false
    @State private var isSearching = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search location...", text: $text)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onSubmit {
                        locationManager.searchLocations(text)
                    }
                    .onChange(of: text) {
                        if !text.isEmpty {
                            isSearching = true
                            locationManager.searchLocations(text)
                        } else {
                            isSearching = false
                            locationManager.locations = []
                        }
                    }
                
                if isSearching {
                    ProgressView()
                        .padding(.trailing, 8)
                }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        locationManager.locations = []
                        isSearching = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            
            if !locationManager.locations.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(locationManager.locations) { location in
                            Button(action: {
                                onLocationSelected(location)
                                text = ""
                                locationManager.locations = []
                                isSearching = false
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.accentColor)
                                    
                                    Text(location.name)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                            }
                            
                            if location.id != locationManager.locations.last?.id {
                                Divider()
                                    .padding(.leading)
                            }
                        }
                    }
                }
                .frame(maxHeight: 250)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: locationManager.locations)
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}

#Preview {
    LocationSearchBar(text: .constant("")) { location in
        print("Selected location: \(location.name)")
    }
    .padding()
} 