import Foundation
import CoreData

@objc(ViewpointEntity)
public class ViewpointEntity: NSManagedObject {
    
}

extension ViewpointEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ViewpointEntity> {
        return NSFetchRequest<ViewpointEntity>(entityName: "ViewpointEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var content: String?
    @NSManaged public var category: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var filePath: String?
    @NSManaged public var tags: String?
    @NSManaged public var wordCount: Int32
    @NSManaged public var characterCount: Int32
}

extension ViewpointEntity: Identifiable {
    
}

extension ViewpointEntity {
    static func create(
        content: String,
        category: String,
        context: NSManagedObjectContext
    ) -> ViewpointEntity {
        let viewpoint = ViewpointEntity(context: context)
        viewpoint.id = UUID()
        viewpoint.content = content
        viewpoint.category = category
        viewpoint.createdAt = Date()
        viewpoint.modifiedAt = Date()
        viewpoint.wordCount = Int32(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
        viewpoint.characterCount = Int32(content.count)
        
        return viewpoint
    }
    
    func update(content: String, category: String) {
        self.content = content
        self.category = category
        self.modifiedAt = Date()
        self.wordCount = Int32(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
        self.characterCount = Int32(content.count)
    }
    
    var tagsArray: [String] {
        get {
            guard let tags = tags else { return [] }
            return tags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            tags = newValue.joined(separator: ",")
        }
    }
}