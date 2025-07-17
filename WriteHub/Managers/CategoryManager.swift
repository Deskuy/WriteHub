import Foundation
import CoreData

class CategoryManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func createCategory(name: String, color: String = "#007AFF", directoryPath: String? = nil) -> CategoryEntity {
        let category = CategoryEntity.create(
            name: name,
            color: color,
            directoryPath: directoryPath,
            context: viewContext
        )
        
        saveContext()
        return category
    }
    
    func updateCategory(_ category: CategoryEntity, name: String, color: String, directoryPath: String? = nil) {
        category.name = name
        category.color = color
        category.directoryPath = directoryPath
        
        saveContext()
    }
    
    func deleteCategory(_ category: CategoryEntity) {
        // Update viewpoints to remove category reference
        let viewpoints = category.viewpointsArray
        for viewpoint in viewpoints {
            viewpoint.category = "Uncategorized"
        }
        
        viewContext.delete(category)
        saveContext()
    }
    
    func getCategories() -> [CategoryEntity] {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    func getCategory(named name: String) -> CategoryEntity? {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching category: \(error)")
            return nil
        }
    }
    
    func getCategoryNames() -> [String] {
        let categories = getCategories()
        return categories.compactMap { $0.name }
    }
    
    func getOrCreateCategory(named name: String) -> CategoryEntity {
        if let existingCategory = getCategory(named: name) {
            return existingCategory
        }
        
        return createCategory(name: name)
    }
    
    func getCategoryStats() -> [(name: String, count: Int, color: String)] {
        let categories = getCategories()
        return categories.map { category in
            (
                name: category.name ?? "Unknown",
                count: category.viewpointCount,
                color: category.color ?? "#007AFF"
            )
        }
    }
    
    func getDefaultCategories() -> [String] {
        return [
            "General",
            "Work",
            "Personal",
            "Ideas",
            "Reflections",
            "Goals",
            "Learning",
            "Creative"
        ]
    }
    
    func setupDefaultCategories() {
        let existingCategories = Set(getCategoryNames())
        let defaultCategories = getDefaultCategories()
        
        let colors = [
            "#007AFF", "#34C759", "#FF9500", "#FF3B30",
            "#AF52DE", "#5856D6", "#00C7BE", "#FF2D92"
        ]
        
        for (index, categoryName) in defaultCategories.enumerated() {
            if !existingCategories.contains(categoryName) {
                let color = colors[index % colors.count]
                _ = createCategory(name: categoryName, color: color)
            }
        }
        
        // Fix existing viewpoints that may not have proper category relationships
        fixViewpointCategoryRelationships()
    }
    
    private func fixViewpointCategoryRelationships() {
        let request: NSFetchRequest<ViewpointEntity> = ViewpointEntity.fetchRequest()
        
        do {
            let viewpoints = try viewContext.fetch(request)
            
            for viewpoint in viewpoints {
                if let categoryName = viewpoint.category,
                   let categoryEntity = getCategory(named: categoryName) {
                    // Check if relationship already exists
                    if !categoryEntity.viewpointsArray.contains(viewpoint) {
                        categoryEntity.addToViewpoints(viewpoint)
                    }
                }
            }
            
            saveContext()
        } catch {
            print("Error fixing viewpoint category relationships: \(error)")
        }
    }
    
    func save() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    private func saveContext() {
        save()
    }
}