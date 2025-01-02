//
//  ContentView.swift
//  TideTimes
//
//  Created by Jeffrey on 2024-12-27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TideViewModel()
    @State private var searchText = ""
    @State private var showingError = false
    @State private var showingLocationMenu = false
    
    private let suggestedLocations = [
        "San Francisco, CA",
        "Seattle, WA",
        "Boston, MA",
        "Miami, FL",
        "Honolulu, HI"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search and location menu
                    HStack(spacing: 12) {
                        // Search bar
                        LocationSearchBar(text: $searchText, onLocationSelected: { location in
                            viewModel.setLocation(location)
                        })
                        
                        // Location menu button
                        Menu {
                            if !viewModel.favoriteLocations.isEmpty {
                                Section("Favorites") {
                                    ForEach(Array(viewModel.favoriteLocations)) { location in
                                        Button(action: {
                                            viewModel.setLocation(location)
                                        }) {
                                            Label(location.name, systemImage: "star.fill")
                                        }
                                    }
                                }
                            }
                            
                            if let recentLocations = viewModel.recentLocations,
                               !recentLocations.isEmpty {
                                if !viewModel.favoriteLocations.isEmpty {
                                    Divider()
                                }
                                Section("Recent") {
                                    ForEach(recentLocations) { location in
                                        Button(action: {
                                            viewModel.setLocation(location)
                                        }) {
                                            Label(location.name, systemImage: "clock")
                                        }
                                    }
                                }
                            }
                            
                            if !viewModel.favoriteLocations.isEmpty || viewModel.recentLocations != nil {
                                Divider()
                            }
                            
                            Section("Suggested") {
                                ForEach(suggestedLocations, id: \.self) { location in
                                    Button(action: {
                                        searchText = location
                                    }) {
                                        Label(location, systemImage: "mappin.circle")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    
                    if let currentLocation = viewModel.currentLocation {
                        LocationContentView(
                            location: currentLocation,
                            viewModel: viewModel,
                            searchText: $searchText
                        )
                    } else {
                        // Welcome sections
                        VStack(spacing: 32) {
                            WelcomeView()
                            
                            // Favorites section
                            if !viewModel.favoriteLocations.isEmpty {
                                LocationSection(
                                    title: "Favorite Locations",
                                    icon: "star.fill",
                                    iconColor: .yellow
                                ) {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(Array(viewModel.favoriteLocations)) { location in
                                                LocationButton(
                                                    location: location,
                                                    icon: "star.fill",
                                                    color: .yellow
                                                ) {
                                                    viewModel.setLocation(location)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // Recent locations section
                            if let recentLocations = viewModel.recentLocations,
                               !recentLocations.isEmpty {
                                LocationSection(
                                    title: "Recent Locations",
                                    icon: "clock",
                                    iconColor: .blue
                                ) {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(recentLocations) { location in
                                                LocationButton(
                                                    location: location,
                                                    icon: "mappin.circle.fill",
                                                    color: .blue
                                                ) {
                                                    viewModel.setLocation(location)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // Suggested locations
                            LocationSection(
                                title: "Suggested Locations",
                                icon: "star",
                                iconColor: .orange
                            ) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(suggestedLocations, id: \.self) { locationName in
                                            LocationButton(
                                                title: locationName,
                                                icon: "mappin.circle.fill",
                                                color: .orange
                                            ) {
                                                searchText = locationName
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tide Times")
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            viewModel.loadSavedLocation()
        }
    }
}

// MARK: - Supporting Views

struct LocationSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.headline)
            }
            .padding(.horizontal)
            
            content
        }
    }
}

struct LocationButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(
        location: Location? = nil,
        title: String? = nil,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) {
        self.title = title ?? location?.name ?? ""
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(Capsule())
        }
    }
}

struct LocationContentView: View {
    let location: Location
    @ObservedObject var viewModel: TideViewModel
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Location header
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(location.name)
                    .font(.title2.weight(.semibold))
                Spacer()
                // Favorite button
                Button(action: {
                    viewModel.toggleFavorite(location)
                }) {
                    Image(systemName: viewModel.isFavorite(location) ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error, 
                         retryAction: {
                             viewModel.setLocation(location)
                         },
                         searchText: $searchText)
            } else if viewModel.tideData.isEmpty {
                NoDataView()
            } else {
                // Tide data content
                VStack(spacing: 24) {
                    CardView {
                        TideGraphView(tideData: viewModel.tideData)
                            .frame(height: 220)
                    }
                    
                    TideDetailsView(tideData: viewModel.tideData)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading tide data...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    @Binding var searchText: String
    
    private var tideError: TideServiceError? {
        error as? TideServiceError
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: tideError?.isNoTidalData == true ? "water.waves.slash" : "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(tideError?.isNoTidalData == true ? .blue : .red)
            
            Text(error.localizedDescription)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if let suggestion = tideError?.suggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if tideError?.isNoTidalData != true {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.bordered)
            }
            
            // Show suggested coastal locations when no tidal data
            if tideError?.isNoTidalData == true {
                SuggestedCoastalLocations { location in
                    searchText = location
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct NoDataView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Data Available", systemImage: "water.waves")
        } description: {
            Text("Unable to load tide data for this location")
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Welcome to Tide Times", systemImage: "water.waves")
        } description: {
            Text("Search for a location to view tide information")
        }
    }
}

struct SuggestedCoastalLocations: View {
    let coastalLocations = [
        "San Francisco, CA",
        "Miami Beach, FL",
        "Cape Cod, MA",
        "Malibu, CA",
        "Waikiki Beach, HI"
    ]
    
    let onLocationSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try these coastal locations:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(coastalLocations, id: \.self) { location in
                        Button(action: {
                            onLocationSelect(location)
                        }) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                Text(location)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            }
    }
}

#Preview {
    ContentView()
}
