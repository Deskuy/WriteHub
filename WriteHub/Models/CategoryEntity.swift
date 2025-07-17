import Foundation
import CoreData

@objc(CategoryEntity)
public class CategoryEntity: NSManagedObject {
    
}

extension CategoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var directoryPath: String?
    @NSManaged public var categoryDescription: String?
    @NSManaged public var viewpoints: NSSet?
}

extension CategoryEntity: Identifiable {
    
}

extension CategoryEntity {
    static func create(
        name: String,
        color: String = "#007AFF",
        directoryPath: String? = nil,
        context: NSManagedObjectContext
    ) -> CategoryEntity {
        let category = CategoryEntity(context: context)
        category.id = UUID()
        category.name = name
        category.color = color
        category.directoryPath = directoryPath
        category.createdAt = Date()
        
        return category
    }
    
    @objc(addViewpointsObject:)
    @NSManaged public func addToViewpoints(_ value: ViewpointEntity)
    
    @objc(removeViewpointsObject:)
    @NSManaged public func removeFromViewpoints(_ value: ViewpointEntity)
    
    @objc(addViewpoints:)
    @NSManaged public func addToViewpoints(_ values: NSSet)
    
    @objc(removeViewpoints:)
    @NSManaged public func removeFromViewpoints(_ values: NSSet)
    
    var viewpointsArray: [ViewpointEntity] {
        let set = viewpoints as? Set<ViewpointEntity> ?? []
        return set.sorted { 
            ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) 
        }
    }
    
    var viewpointCount: Int {
        return viewpoints?.count ?? 0
    }
}