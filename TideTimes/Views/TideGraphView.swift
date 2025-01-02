import SwiftUI
import Charts

struct TideGraphView: View {
    let tideData: [TideData]
    
    private var filteredData: [TideData] {
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .hour, value: 24, to: now)!
        return tideData
            .filter { $0.time >= now && $0.time <= tomorrow }
            .sorted { $0.time < $1.time }
    }
    
    private var heightRange: ClosedRange<Double> {
        guard let minHeight = filteredData.map({ $0.height }).min(),
              let maxHeight = filteredData.map({ $0.height }).max() else {
            return 0...1
        }
        let padding = (maxHeight - minHeight) * 0.2
        return (minHeight - padding)...(maxHeight + padding)
    }
    
    var body: some View {
        Chart(filteredData) { tide in
            // Main tide curve
            LineMark(
                x: .value("Time", tide.time),
                y: .value("Height", tide.height)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.4)]))
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            // Extreme points and current level
            PointMark(
                x: .value("Time", tide.time),
                y: .value("Height", tide.height)
            )
            .foregroundStyle(tide.type == .current ? Color.green : Color.blue)
            .symbolSize(tide.type == .current ? 100 : 50)
            .annotation(position: .top) {
                if tide.type != .current {
                    Text(String(format: "%.1fm", tide.height))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartOverlay { proxy in
            // Current time indicator
            GeometryReader { geometry in
                let xPosition = proxy.position(forX: Date()) ?? 0
                Rectangle()
                    .fill(.secondary.opacity(0.5))
                    .frame(width: 1)
                    .frame(height: geometry.size.height)
                    .overlay {
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .position(x: xPosition, y: geometry.size.height / 2)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let height = value.as(Double.self) {
                        Text(String(format: "%.1fm", height))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYScale(domain: heightRange)
        .chartPlotStyle { plot in
            plot
                .background(.quaternary.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

// Preview provider
#Preview {
    let now = Date()
    let tideData = [
        TideData(time: now.addingTimeInterval(-6 * 3600), height: 0.5, type: .low),
        TideData(time: now, height: 1.2, type: .current),
        TideData(time: now.addingTimeInterval(6 * 3600), height: 2.1, type: .high),
        TideData(time: now.addingTimeInterval(12 * 3600), height: 0.3, type: .low)
    ]
    
    TideGraphView(tideData: tideData)
        .frame(height: 200)
        .padding()
} 
