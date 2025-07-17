import Foundation
import CoreData

class FileSystemManager: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let fileManager = FileManager.default
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func getBaseExportDirectory() -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("WriteHub_Export")
    }
    
    func setupExportDirectory() throws {
        let baseDir = getBaseExportDirectory()
        try fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    func exportViewpoint(_ viewpoint: ViewpointEntity, to customPath: String? = nil) throws -> URL {
        try setupExportDirectory()
        
        let baseDir = getBaseExportDirectory()
        let categoryName = viewpoint.category ?? "Uncategorized"
        let categoryDir = baseDir.appendingPathComponent(categoryName)
        
        try fileManager.createDirectory(at: categoryDir, withIntermediateDirectories: true, attributes: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: viewpoint.createdAt ?? Date())
        
        let fileName = "viewpoint_\(dateString).txt"
        let filePath = categoryDir.appendingPathComponent(fileName)
        
        var content = ""
        content += "Created: \(viewpoint.createdAt?.formatted() ?? "Unknown")\n"
        content += "Category: \(categoryName)\n"
        if let tags = viewpoint.tags, !tags.isEmpty {
            content += "Tags: \(tags)\n"
        }
        content += "Word Count: \(viewpoint.wordCount)\n"
        content += "Character Count: \(viewpoint.characterCount)\n"
        content += "\n---\n\n"
        content += viewpoint.content ?? ""
        
        try content.write(to: filePath, atomically: true, encoding: .utf8)
        
        // Update viewpoint with file path
        viewpoint.filePath = filePath.path
        try viewContext.save()
        
        return filePath
    }
    
    func exportAllViewpoints() throws -> [URL] {
        let viewpointManager = ViewpointManager(viewContext: viewContext)
        let viewpoints = viewpointManager.getViewpoints()
        
        var exportedFiles: [URL] = []
        
        for viewpoint in viewpoints {
            do {
                let filePath = try exportViewpoint(viewpoint)
                exportedFiles.append(filePath)
            } catch {
                print("Error exporting viewpoint: \(error)")
                // Continue with other viewpoints
            }
        }
        
        return exportedFiles
    }
    
    func exportCategory(_ category: String) throws -> [URL] {
        let viewpointManager = ViewpointManager(viewContext: viewContext)
        let viewpoints = viewpointManager.getViewpoints(for: category)
        
        var exportedFiles: [URL] = []
        
        for viewpoint in viewpoints {
            do {
                let filePath = try exportViewpoint(viewpoint)
                exportedFiles.append(filePath)
            } catch {
                print("Error exporting viewpoint: \(error)")
                // Continue with other viewpoints
            }
        }
        
        return exportedFiles
    }
    
    func importViewpointsFromDirectory(_ directoryURL: URL) throws -> [ViewpointEntity] {
        let viewpointManager = ViewpointManager(viewContext: viewContext)
        var importedViewpoints: [ViewpointEntity] = []
        
        let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        
        for fileURL in fileURLs {
            if fileURL.pathExtension.lowercased() == "txt" {
                do {
                    let content = try String(contentsOf: fileURL, encoding: .utf8)
                    let categoryName = directoryURL.lastPathComponent
                    
                    let viewpoint = viewpointManager.createViewpoint(
                        content: content,
                        category: categoryName
                    )
                    
                    viewpoint.filePath = fileURL.path
                    importedViewpoints.append(viewpoint)
                } catch {
                    print("Error importing file \(fileURL.path): \(error)")
                    // Continue with other files
                }
            }
        }
        
        try viewContext.save()
        return importedViewpoints
    }
    
    func createBackup() throws -> URL {
        let backupDir = getBaseExportDirectory().appendingPathComponent("Backups")
        try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true, attributes: nil)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        let backupFile = backupDir.appendingPathComponent("WriteHub_Backup_\(dateString).json")
        
        let viewpointManager = ViewpointManager(viewContext: viewContext)
        let categoryManager = CategoryManager(viewContext: viewContext)
        
        let viewpoints = viewpointManager.getViewpoints()
        let categories = categoryManager.getCategories()
        
        let backup = BackupData(
            viewpoints: viewpoints.map { viewpoint in
                BackupViewpoint(
                    id: viewpoint.id?.uuidString ?? UUID().uuidString,
                    content: viewpoint.content ?? "",
                    category: viewpoint.category ?? "Uncategorized",
                    createdAt: viewpoint.createdAt ?? Date(),
                    modifiedAt: viewpoint.modifiedAt ?? Date(),
                    tags: viewpoint.tags ?? "",
                    wordCount: Int(viewpoint.wordCount),
                    characterCount: Int(viewpoint.characterCount)
                )
            },
            categories: categories.map { category in
                BackupCategory(
                    id: category.id?.uuidString ?? UUID().uuidString,
                    name: category.name ?? "",
                    color: category.color ?? "#007AFF",
                    directoryPath: category.directoryPath ?? ""
                )
            },
            exportDate: Date()
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(backup)
        try data.write(to: backupFile)
        
        return backupFile
    }
    
    func restoreFromBackup(_ backupURL: URL) throws -> (viewpoints: Int, categories: Int) {
        let data = try Data(contentsOf: backupURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(BackupData.self, from: data)
        
        let viewpointManager = ViewpointManager(viewContext: viewContext)
        let categoryManager = CategoryManager(viewContext: viewContext)
        
        // Restore categories first
        for backupCategory in backup.categories {
            let category = categoryManager.createCategory(
                name: backupCategory.name,
                color: backupCategory.color,
                directoryPath: backupCategory.directoryPath.isEmpty ? nil : backupCategory.directoryPath
            )
            category.id = UUID(uuidString: backupCategory.id)
        }
        
        // Restore viewpoints
        for backupViewpoint in backup.viewpoints {
            let viewpoint = viewpointManager.createViewpoint(
                content: backupViewpoint.content,
                category: backupViewpoint.category
            )
            viewpoint.id = UUID(uuidString: backupViewpoint.id)
            viewpoint.createdAt = backupViewpoint.createdAt
            viewpoint.modifiedAt = backupViewpoint.modifiedAt
            viewpoint.tags = backupViewpoint.tags
            viewpoint.wordCount = Int32(backupViewpoint.wordCount)
            viewpoint.characterCount = Int32(backupViewpoint.characterCount)
        }
        
        try viewContext.save()
        
        return (backup.viewpoints.count, backup.categories.count)
    }
}

// Backup data structures
struct BackupData: Codable {
    let viewpoints: [BackupViewpoint]
    let categories: [BackupCategory]
    let exportDate: Date
}

struct BackupViewpoint: Codable {
    let id: String
    let content: String
    let category: String
    let createdAt: Date
    let modifiedAt: Date
    let tags: String
    let wordCount: Int
    let characterCount: Int
}

struct BackupCategory: Codable {
    let id: String
    let name: String
    let color: String
    let directoryPath: String
}