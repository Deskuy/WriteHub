import SwiftUI

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTimeRange = TimeRange.month
    @State private var showingExportOptions = false
    @State private var showingImportOptions = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var statisticsManager: StatisticsManager {
        StatisticsManager(viewContext: viewContext)
    }
    
    private var fileSystemManager: FileSystemManager {
        FileSystemManager(viewContext: viewContext)
    }
    
    private var totalStats: (viewpoints: Int, words: Int, characters: Int, categories: Int) {
        statisticsManager.getTotalStats()
    }
    
    private var streakData: (current: Int, longest: Int) {
        statisticsManager.getStreakData()
    }
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Statistics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Menu {
                            Button("Export All Viewpoints") {
                                exportAllViewpoints()
                            }
                            
                            Button("Create Backup") {
                                createBackup()
                            }
                            
                            Divider()
                            
                            Button("Import from Directory") {
                                showingImportOptions = true
                            }
                            
                            Button("Restore from Backup") {
                                showingImportOptions = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Overall Stats
                    VStack(spacing: 16) {
                        Text("Overall Statistics")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            StatsCard(
                                title: "Total Viewpoints",
                                value: "\(totalStats.viewpoints)",
                                icon: "doc.text.fill",
                                color: .blue
                            )
                            
                            StatsCard(
                                title: "Total Words",
                                value: "\(totalStats.words)",
                                icon: "textformat.abc",
                                color: .green
                            )
                            
                            StatsCard(
                                title: "Total Characters",
                                value: "\(totalStats.characters)",
                                icon: "character.cursor.ibeam",
                                color: .orange
                            )
                            
                            StatsCard(
                                title: "Categories",
                                value: "\(totalStats.categories)",
                                icon: "folder.fill",
                                color: .purple
                            )
                        }
                    }
                    
                    // Streak Information
                    VStack(spacing: 16) {
                        Text("Writing Streaks")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 20) {
                            StreakCard(
                                title: "Current Streak",
                                value: streakData.current,
                                subtitle: "days",
                                color: .blue
                            )
                            
                            StreakCard(
                                title: "Longest Streak",
                                value: streakData.longest,
                                subtitle: "days",
                                color: .green
                            )
                        }
                    }
                    
                    // Time Range Analysis
                    VStack(spacing: 16) {
                        HStack {
                            Text("Analysis")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 200)
                        }
                        
                        TimeRangeAnalysis(
                            timeRange: selectedTimeRange,
                            statisticsManager: statisticsManager
                        )
                    }
                    
                    // Category Distribution
                    CategoryDistributionView(viewContext: viewContext)
                }
                .padding()
            }
        }
        .alert("Message", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .fileImporter(
            isPresented: $showingImportOptions,
            allowedContentTypes: [.folder, .json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
    }
    
    private func exportAllViewpoints() {
        do {
            let exportedFiles = try fileSystemManager.exportAllViewpoints()
            alertMessage = "Successfully exported \(exportedFiles.count) viewpoints to your Documents folder."
            showingAlert = true
        } catch {
            alertMessage = "Error exporting viewpoints: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func createBackup() {
        do {
            let backupFile = try fileSystemManager.createBackup()
            alertMessage = "Backup created successfully at: \(backupFile.path)"
            showingAlert = true
        } catch {
            alertMessage = "Error creating backup: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                if url.pathExtension.lowercased() == "json" {
                    // Restore from backup
                    let (viewpoints, categories) = try fileSystemManager.restoreFromBackup(url)
                    alertMessage = "Successfully restored \(viewpoints) viewpoints and \(categories) categories from backup."
                } else {
                    // Import from directory
                    let importedViewpoints = try fileSystemManager.importViewpointsFromDirectory(url)
                    alertMessage = "Successfully imported \(importedViewpoints.count) viewpoints from directory."
                }
                showingAlert = true
            } catch {
                alertMessage = "Error importing: \(error.localizedDescription)"
                showingAlert = true
            }
        case .failure(let error):
            alertMessage = "Error selecting file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, design: .default))
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StreakCard: View {
    let title: String
    let value: Int
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .offset(y: -8)
            }
            
            // Streak visualization
            HStack(spacing: 2) {
                ForEach(0..<min(value, 7), id: \.self) { _ in
                    Rectangle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .cornerRadius(1)
                }
                
                if value > 7 {
                    Text("...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct TimeRangeAnalysis: View {
    let timeRange: StatisticsView.TimeRange
    let statisticsManager: StatisticsManager
    
    private var stats: [DailyStatsEntity] {
        switch timeRange {
        case .week:
            return statisticsManager.getWeeklyStats(for: Date())
        case .month:
            return statisticsManager.getMonthlyStats(for: Date())
        case .year:
            return statisticsManager.getContributionData(for: Calendar.current.component(.year, from: Date()))
        }
    }
    
    private var totalViewpoints: Int {
        stats.reduce(0) { $0 + Int($1.viewpointCount) }
    }
    
    private var totalWords: Int {
        stats.reduce(0) { $0 + Int($1.totalWordCount) }
    }
    
    private var averagePerDay: Double {
        guard !stats.isEmpty else { return 0 }
        return Double(totalViewpoints) / Double(stats.count)
    }
    
    private var activeDays: Int {
        stats.filter { $0.viewpointCount > 0 }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Summary for selected time range
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Viewpoints")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalViewpoints)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Average per Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", averagePerDay))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Active Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(activeDays)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Simple chart visualization
            if !stats.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Over Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SimpleBarChart(data: stats, maxValue: stats.map { Int($0.viewpointCount) }.max() ?? 1)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
}

struct SimpleBarChart: View {
    let data: [DailyStatsEntity]
    let maxValue: Int
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(data.indices, id: \.self) { index in
                let value = Int(data[index].viewpointCount)
                let height = maxValue > 0 ? CGFloat(value) / CGFloat(maxValue) * 60 : 0
                
                Rectangle()
                    .fill(value > 0 ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: max(height, 2))
                    .cornerRadius(1)
            }
        }
        .frame(height: 60)
    }
}

struct CategoryDistributionView: View {
    let viewContext: NSManagedObjectContext
    
    private var categoryManager: CategoryManager {
        CategoryManager(viewContext: viewContext)
    }
    
    private var categoryStats: [(name: String, count: Int, color: String)] {
        categoryManager.getCategoryStats()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Category Distribution")
                .font(.title2)
                .fontWeight(.semibold)
            
            if categoryStats.isEmpty {
                Text("No categories found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(categoryStats, id: \.name) { category in
                        CategoryDistributionRow(
                            name: category.name,
                            count: category.count,
                            color: category.color,
                            total: categoryStats.reduce(0) { $0 + $1.count }
                        )
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }
}

struct CategoryDistributionRow: View {
    let name: String
    let count: Int
    let color: String
    let total: Int
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) * 100 : 0
    }
    
    var body: some View {
        HStack {
            // Color indicator
            Circle()
                .fill(Color(hex: color) ?? .blue)
                .frame(width: 12, height: 12)
            
            // Category name
            Text(name)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Count
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Percentage
            Text(String(format: "%.1f%%", percentage))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}