import Foundation
import CoreData

@objc(DailyStatsEntity)
public class DailyStatsEntity: NSManagedObject {
    
}

extension DailyStatsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyStatsEntity> {
        return NSFetchRequest<DailyStatsEntity>(entityName: "DailyStatsEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var viewpointCount: Int32
    @NSManaged public var totalWordCount: Int32
    @NSManaged public var totalCharacterCount: Int32
    @NSManaged public var categories: String?
    @NSManaged public var createdAt: Date?
}

extension DailyStatsEntity: Identifiable {
    
}

extension DailyStatsEntity {
    static func create(
        date: Date,
        viewpointCount: Int,
        totalWordCount: Int,
        totalCharacterCount: Int,
        categories: [String],
        context: NSManagedObjectContext
    ) -> DailyStatsEntity {
        let stats = DailyStatsEntity(context: context)
        stats.id = UUID()
        stats.date = date
        stats.viewpointCount = Int32(viewpointCount)
        stats.totalWordCount = Int32(totalWordCount)
        stats.totalCharacterCount = Int32(totalCharacterCount)
        stats.categories = categories.joined(separator: ",")
        stats.createdAt = Date()
        
        return stats
    }
    
    static func findOrCreate(
        for date: Date,
        context: NSManagedObjectContext
    ) -> DailyStatsEntity {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<DailyStatsEntity> = DailyStatsEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let existingStats = results.first {
                return existingStats
            }
        } catch {
            print("Error fetching daily stats: \(error)")
        }
        
        // Create new stats if none found
        return create(
            date: startOfDay,
            viewpointCount: 0,
            totalWordCount: 0,
            totalCharacterCount: 0,
            categories: [],
            context: context
        )
    }
    
    var categoriesArray: [String] {
        get {
            guard let categories = categories else { return [] }
            return categories.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            categories = newValue.joined(separator: ",")
        }
    }
    
    var intensity: Int {
        // Calculate intensity level (0-4) based on viewpoint count
        switch viewpointCount {
        case 0: return 0
        case 1: return 1
        case 2...3: return 2
        case 4...6: return 3
        default: return 4
        }
    }
}