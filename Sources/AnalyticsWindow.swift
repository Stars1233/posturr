import SwiftUI
import Charts
import AppKit

// MARK: - Window Controller

class AnalyticsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Posture Analytics"
        window.center()
        
        // Hide from Dock initially if main app is hidden, but this is a secondary window.
        // Usually we want it to act like a normal window when open.
        
        self.init(window: window)
        
        let view = AnalyticsView()
        window.contentViewController = NSHostingController(rootView: view)
    }
}

// MARK: - SwiftUI Views

struct AnalyticsView: View {
    @ObservedObject var manager = AnalyticsManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Your Posture Health")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Track your habits and improvement over time")
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Today's Score Card
                HStack(spacing: 16) {
                    ScoreRing(score: manager.todayStats.postureScore)
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading) {
                        Text("Today's Score")
                            .font(.headline)
                        Text(String(format: "%.0f%%", manager.todayStats.postureScore))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(manager.todayStats.postureScore))
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            // Main Content Grid
            HStack(alignment: .top, spacing: 20) {
                // Left Col: Stats
                VStack(spacing: 16) {
                    StatCard(
                        title: "Monitoring Time",
                        value: formatDuration(manager.todayStats.totalSeconds),
                        icon: "clock"
                    )
                    
                    StatCard(
                        title: "Slouch Duration",
                        value: formatDuration(manager.todayStats.slouchSeconds),
                        icon: "figure.fall",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Slouch Events",
                        value: "\(manager.todayStats.slouchCount)",
                        icon: "exclamationmark.circle",
                        color: .red
                    )
                }
                .frame(width: 200)
                
                // Right Col: Charts
                VStack(alignment: .leading) {
                    Text("Last 7 Days")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    let history = manager.getLast7Days()
                    
                    Chart(history) { day in
                        if day.totalSeconds > 0 {
                            BarMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Score", day.postureScore)
                            )
                            .foregroundStyle(scoreColor(day.postureScore))
                            .annotation(position: .top) {
                                Text(String(format: "%.0f", day.postureScore))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            // Invisible bar to maintain x-axis spacing
                            BarMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Score", 0)
                            )
                            .opacity(0)
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .frame(minHeight: 200)
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    func scoreColor(_ score: Double) -> Color {
        if score >= 85 { return .green }
        if score >= 70 { return .yellow }
        return .red
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct ScoreRing: View {
    let score: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: score / 100.0)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.red, .yellow, .green]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: score)
        }
    }
}
