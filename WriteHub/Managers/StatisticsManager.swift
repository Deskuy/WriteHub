import Foundation
import CoreData

class StatisticsManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func updateDailyStats(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Get viewpoints for the day
        let viewpointsRequest: NSFetchRequest<ViewpointEntity> = ViewpointEntity.fetchRequest()
        viewpointsRequest.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let viewpoints = try viewContext.fetch(viewpointsRequest)
            
            let viewpointCount = viewpoints.count
            let totalWordCount = viewpoints.reduce(0) { $0 + Int($1.wordCount) }
            let totalCharacterCount = viewpoints.reduce(0) { $0 + Int($1.characterCount) }
            let categories = Set(viewpoints.compactMap { $0.category }).sorted()
            
            let dailyStats = DailyStatsEntity.findOrCreate(for: startOfDay, context: viewContext)
            dailyStats.viewpointCount = Int32(viewpointCount)
            dailyStats.totalWordCount = Int32(totalWordCount)
            dailyStats.totalCharacterCount = Int32(totalCharacterCount)
            dailyStats.categoriesArray = categories
            
            try viewContext.save()
        } catch {
            print("Error updating daily stats: \(error)")
        }
    }
    
    func getDailyStats(for date: Date) -> DailyStatsEntity? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<DailyStatsEntity> = DailyStatsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching daily stats: \(error)")
            return nil
        }
    }
    
    func getContributionData(for year: Int) -> [DailyStatsEntity] {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        
        let request: NSFetchRequest<DailyStatsEntity> = DailyStatsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfYear as NSDate, endOfYear as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DailyStatsEntity.date, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching contribution data: \(error)")
            return []
        }
    }
    
    func getWeeklyStats(for date: Date) -> [DailyStatsEntity] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
        
        let request: NSFetchRequest<DailyStatsEntity> = DailyStatsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfWeek as NSDate, endOfWeek as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DailyStatsEntity.date, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching weekly stats: \(error)")
            return []
        }
    }
    
    func getMonthlyStats(for date: Date) -> [DailyStatsEntity] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let request: NSFetchRequest<DailyStatsEntity> = DailyStatsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfMonth as NSDate, endOfMonth as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DailyStatsEntity.date, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching monthly stats: \(error)")
            return []
        }
    }
    
    func getTotalStats() -> (viewpoints: Int, words: Int, characters: Int, categories: Int) {
        let viewpointsRequest: NSFetchRequest<ViewpointEntity> = ViewpointEntity.fetchRequest()
        
        do {
            let viewpoints = try viewContext.fetch(viewpointsRequest)
            let totalViewpoints = viewpoints.count
            let totalWords = viewpoints.reduce(0) { $0 + Int($1.wordCount) }
            let totalCharacters = viewpoints.reduce(0) { $0 + Int($1.characterCount) }
            let uniqueCategories = Set(viewpoints.compactMap { $0.category }).count
            
            return (totalViewpoints, totalWords, totalCharacters, uniqueCategories)
        } catch {
            print("Error fetching total stats: \(error)")
            return (0, 0, 0, 0)
        }
    }
    
    func getStreakData() -> (current: Int, longest: Int) {
        let allStats = getAllDailyStats()
        let sortedStats = allStats.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Calculate current streak (from today backwards)
        for dayOffset in 0..<365 {
            let checkDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let hasActivity = sortedStats.first { 
                calendar.isDate($0.date ?? Date.distantPast, inSameDayAs: checkDate) && $0.viewpointCount > 0
            } != nil
            
            if hasActivity {
                if dayOffset == 0 || currentStreak > 0 {
                    currentStreak += 1
                }
            } else {
                break
            }
        }
        
        // Calculate longest streak
        for stats in sortedStats {
            if stats.viewpointCount > 0 {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
        }
        
        return (currentStreak, longestStreak)
    }
    
    private func getAllDailyStats() -> [DailyStatsEntity] {
        let request: NSFetchRequest<DailyStatsEntity> = DailyStatsEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DailyStatsEntity.date, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching all daily stats: \(error)")
            return []
        }
    }
}