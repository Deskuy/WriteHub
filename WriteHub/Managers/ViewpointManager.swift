import Foundation
import CoreData

class ViewpointManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func createViewpoint(content: String, category: String) -> ViewpointEntity {
        let viewpoint = ViewpointEntity.create(
            content: content,
            category: category,
            context: viewContext
        )
        
        // Establish relationship with CategoryEntity
        let categoryManager = CategoryManager(viewContext: viewContext)
        if let categoryEntity = categoryManager.getCategory(named: category) {
            categoryEntity.addToViewpoints(viewpoint)
        }
        
        updateDailyStats(for: Date())
        saveContext()
        
        return viewpoint
    }
    
    func updateViewpoint(_ viewpoint: ViewpointEntity, content: String, category: String) {
        let oldCategory = viewpoint.category
        viewpoint.update(content: content, category: category)
        
        // Update category relationships if category changed
        if oldCategory != category {
            let categoryManager = CategoryManager(viewContext: viewContext)
            
            // Remove from old category
            if let oldCategoryName = oldCategory,
               let oldCategoryEntity = categoryManager.getCategory(named: oldCategoryName) {
                oldCategoryEntity.removeFromViewpoints(viewpoint)
            }
            
            // Add to new category
            if let newCategoryEntity = categoryManager.getCategory(named: category) {
                newCategoryEntity.addToViewpoints(viewpoint)
            }
        }
        
        updateDailyStats(for: viewpoint.createdAt ?? Date())
        saveContext()
    }
    
    func deleteViewpoint(_ viewpoint: ViewpointEntity) {
        // Remove from category relationship
        if let category = viewpoint.category {
            let categoryManager = CategoryManager(viewContext: viewContext)
            if let categoryEntity = categoryManager.getCategory(named: category) {
                categoryEntity.removeFromViewpoints(viewpoint)
            }
        }
        
        viewContext.delete(viewpoint)
        updateDailyStats(for: viewpoint.createdAt ?? Date())
        saveContext()
    }
    
    func getViewpoints() -> [ViewpointEntity] {
        let request: NSFetchRequest<ViewpointEntity> = ViewpointEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ViewpointEntity.createdAt, ascending: false)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching viewpoints: \(error)")
            return []
        }
    }
    
    func getViewpoints(for category: String) -> [ViewpointEntity] {
        let request: NSFetchRequest<ViewpointEntity> = ViewpointEntity.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ViewpointEntity.createdAt, ascending: false)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching viewpoints for category: \(error)")
            return []
        }
    }
    
    func getViewpoints(for date: Date) -> [ViewpointEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<ViewpointEntity> = ViewpointEntity.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ViewpointEntity.createdAt, ascending: false)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching viewpoints for date: \(error)")
            return []
        }
    }
    
    func searchViewpoints(query: String) -> [ViewpointEntity] {
        let request: NSFetchRequest<ViewpointEntity> = ViewpointEntity.fetchRequest()
        request.predicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ViewpointEntity.createdAt, ascending: false)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error searching viewpoints: \(error)")
            return []
        }
    }
    
    private func updateDailyStats(for date: Date) {
        let statsManager = StatisticsManager(viewContext: viewContext)
        statsManager.updateDailyStats(for: date)
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}