import SwiftUI

struct TideDetailsView: View {
    let tideData: [TideData]
    
    private var next24HoursTides: [TideData] {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .hour, value: 24, to: now)!
        return tideData.filter { $0.time >= now && $0.time <= tomorrow }
    }
    
    private var extremeTides: (nextHigh: TideData?, nextLow: TideData?) {
        let now = Date()
        let futureExtremes = tideData.filter { $0.time > now }
        let nextHigh = futureExtremes.first { $0.type == .high }
        let nextLow = futureExtremes.first { $0.type == .low }
        return (nextHigh, nextLow)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Next tide events card
            VStack(spacing: 16) {
                Text("Next Tide Events")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 20) {
                    if let nextHigh = extremeTides.nextHigh {
                        TideEventCard(title: "Next High", tideData: nextHigh)
                    }
                    if let nextLow = extremeTides.nextLow {
                        TideEventCard(title: "Next Low", tideData: nextLow)
                    }
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
            
            // 24-hour tide table
            VStack(alignment: .leading, spacing: 12) {
                Text("24 Hour Forecast")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(next24HoursTides) { tide in
                            TideRowView(tide: tide)
                        }
                    }
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
        .padding()
    }
}

struct TideEventCard: View {
    let title: String
    let tideData: TideData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(String(format: "%.1f m", tideData.height))
                .font(.title2)
                .bold()
            
            Text(tideData.time.formatted(date: .omitted, time: .shortened))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
        }
    }
}

struct TideRowView: View {
    let tide: TideData
    
    private var tideTypeIcon: String {
        switch tide.type {
        case .high: return "arrow.up.circle.fill"
        case .low: return "arrow.down.circle.fill"
        case .current: return "circle.fill"
        }
    }
    
    private var tideTypeColor: Color {
        switch tide.type {
        case .high: return .blue
        case .low: return .orange
        case .current: return .gray
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: tideTypeIcon)
                .foregroundStyle(tideTypeColor)
            
            Text(tide.time.formatted(date: .omitted, time: .shortened))
                .frame(width: 80, alignment: .leading)
            
            Text(String(format: "%.1f m", tide.height))
                .frame(width: 60)
            
            if tide.type != .current {
                Text(tide.type.rawValue)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(tide.type != .current ? Color.secondary.opacity(0.1) : nil)
        .cornerRadius(8)
    }
}

#Preview {
    TideDetailsView(tideData: [
        TideData(time: Date(), height: 1.2, type: .current),
        TideData(time: Date().addingTimeInterval(3600), height: 2.1, type: .high),
        TideData(time: Date().addingTimeInterval(7200), height: 0.5, type: .low)
    ])
} 