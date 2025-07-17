import SwiftUI

struct ContributionGraphView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedDate: Date?
    @State private var showingDayDetail = false
    
    private var statisticsManager: StatisticsManager {
        StatisticsManager(viewContext: viewContext)
    }
    
    private var contributionData: [DailyStatsEntity] {
        statisticsManager.getContributionData(for: selectedYear)
    }
    
    private var streakData: (current: Int, longest: Int) {
        statisticsManager.getStreakData()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Contribution Graph")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Year selector
                    HStack {
                        Button(action: {
                            selectedYear -= 1
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Text("\(selectedYear)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedYear += 1
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(selectedYear >= Calendar.current.component(.year, from: Date()))
                    }
                    .frame(maxWidth: 200)
                    
                    // Stats summary
                    HStack(spacing: 20) {
                        StatsSummaryCard(
                            title: "Current Streak",
                            value: "\(streakData.current)",
                            subtitle: "days"
                        )
                        
                        StatsSummaryCard(
                            title: "Longest Streak",
                            value: "\(streakData.longest)",
                            subtitle: "days"
                        )
                        
                        StatsSummaryCard(
                            title: "This Year",
                            value: "\(contributionData.reduce(0) { $0 + Int($1.viewpointCount) })",
                            subtitle: "viewpoints"
                        )
                    }
                }
                
                // Contribution graph
                VStack(spacing: 12) {
                    ContributionCalendar(
                        year: selectedYear,
                        data: contributionData,
                        onDateSelected: { date in
                            selectedDate = date
                            showingDayDetail = true
                        }
                    )
                    
                    // Legend
                    ContributionLegend()
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showingDayDetail) {
                if let date = selectedDate {
                    DayDetailView(date: date, statisticsManager: statisticsManager)
                        .frame(minWidth: 600, minHeight: 500)
                }
            }
        }
    }
}

struct StatsSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ContributionCalendar: View {
    let year: Int
    let data: [DailyStatsEntity]
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2
    
    private var weeks: [[Date?]] {
        generateWeeks()
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Month labels
            HStack(spacing: 0) {
                ForEach(monthLabels, id: \.offset) { month in
                    Text(month.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: month.width)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.leading, 30)
            
            // Calendar grid
            HStack(alignment: .top, spacing: cellSpacing) {
                // Day labels
                VStack(spacing: cellSpacing) {
                    ForEach(dayLabels, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: cellSize)
                    }
                }
                
                // Weeks
                HStack(spacing: cellSpacing) {
                    ForEach(weeks.indices, id: \.self) { weekIndex in
                        VStack(spacing: cellSpacing) {
                            ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                                if let date = weeks[weekIndex][dayIndex] {
                                    ContributionCell(
                                        date: date,
                                        intensity: getIntensity(for: date),
                                        size: cellSize
                                    ) {
                                        onDateSelected(date)
                                    }
                                } else {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func generateWeeks() -> [[Date?]] {
        var weeks: [[Date?]] = []
        
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        
        // Find the first Sunday of the year or before
        var currentDate = startOfYear
        while calendar.component(.weekday, from: currentDate) != 1 {
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        while currentDate < endOfYear {
            var week: [Date?] = []
            
            for _ in 0..<7 {
                if calendar.component(.year, from: currentDate) == year {
                    week.append(currentDate)
                } else {
                    week.append(nil)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            weeks.append(week)
        }
        
        return weeks
    }
    
    private var monthLabels: [(name: String, width: CGFloat, offset: Int)] {
        let months = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ]
        
        var labels: [(name: String, width: CGFloat, offset: Int)] = []
        let weeksPerMonth = weeks.count / 12
        let baseWidth = (cellSize + cellSpacing) * CGFloat(weeksPerMonth)
        
        for (index, month) in months.enumerated() {
            labels.append((name: month, width: baseWidth, offset: index))
        }
        
        return labels
    }
    
    private var dayLabels: [String] {
        ["", "M", "", "W", "", "F", ""]
    }
    
    private func getIntensity(for date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        if let stats = data.first(where: { calendar.isDate($0.date ?? Date.distantPast, inSameDayAs: dayStart) }) {
            return stats.intensity
        }
        return 0
    }
}

struct ContributionCell: View {
    let date: Date
    let intensity: Int
    let size: CGFloat
    let onTap: () -> Void
    
    private var color: Color {
        switch intensity {
        case 0: return Color(.controlBackgroundColor)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        case 4: return Color.green.opacity(0.9)
        default: return Color.green
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(.separatorColor), lineWidth: 0.5)
            )
            .onTapGesture {
                onTap()
            }
            .help(tooltipText)
    }
    
    private var tooltipText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: date)
        
        if intensity == 0 {
            return "\(dateString): No activity"
        } else if intensity == 1 {
            return "\(dateString): 1 viewpoint"
        } else {
            return "\(dateString): \(intensity) viewpoints"
        }
    }
}

struct ContributionLegend: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Less")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 2) {
                ForEach(0..<5) { intensity in
                    Rectangle()
                        .fill(legendColor(for: intensity))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                }
            }
            
            Text("More")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func legendColor(for intensity: Int) -> Color {
        switch intensity {
        case 0: return Color(.controlBackgroundColor)
        case 1: return Color.green.opacity(0.3)
        case 2: return Color.green.opacity(0.5)
        case 3: return Color.green.opacity(0.7)
        case 4: return Color.green.opacity(0.9)
        default: return Color.green
        }
    }
}

struct DayDetailView: View {
    let date: Date
    let statisticsManager: StatisticsManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    private var dailyStats: DailyStatsEntity? {
        statisticsManager.getDailyStats(for: date)
    }
    
    private var viewpointManager: ViewpointManager {
        ViewpointManager(viewContext: viewContext)
    }
    
    private var viewpoints: [ViewpointEntity] {
        viewpointManager.getViewpoints(for: date)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(date.formatted(date: .complete, time: .omitted))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 20) {
                        StatPill(title: "Viewpoints", value: "\(dailyStats?.viewpointCount ?? 0)")
                        StatPill(title: "Words", value: "\(dailyStats?.totalWordCount ?? 0)")
                        StatPill(title: "Characters", value: "\(dailyStats?.totalCharacterCount ?? 0)")
                    }
                }
                
                // Categories
                if let categories = dailyStats?.categoriesArray, !categories.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categories")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                CategoryPill(name: category)
                            }
                        }
                    }
                }
                
                // Viewpoints
                if !viewpoints.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Viewpoints")
                            .font(.headline)
                        
                        List {
                            ForEach(viewpoints, id: \.id) { viewpoint in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(viewpoint.content ?? "")
                                        .font(.body)
                                        .lineLimit(5)
                                    
                                    HStack {
                                        Text(viewpoint.category ?? "Uncategorized")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                        
                                        Spacer()
                                        
                                        Text(viewpoint.createdAt?.formatted(date: .omitted, time: .shortened) ?? "")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64, design: .default))
                            .foregroundColor(.secondary)
                        
                        Text("No viewpoints on this day")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatPill: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct CategoryPill: View {
    let name: String
    
    var body: some View {
        Text(name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
}

#Preview {
    ContributionGraphView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}