import SwiftUI

struct CategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddCategory = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedCategory: CategoryEntity?
    @State private var showingCategoryDetail = false
    
    private var categoryManager: CategoryManager {
        CategoryManager(viewContext: viewContext)
    }
    
    private var categories: [CategoryEntity] {
        categoryManager.getCategories()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Text("Categories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if categories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 64, design: .default))
                            .foregroundColor(.secondary)
                        
                        Text("No categories yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Create your first category to organize your viewpoints")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Create Category") {
                            showingAddCategory = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(categories, id: \.id) { category in
                            CategoryRowView(category: category) {
                                selectedCategory = category
                                showingCategoryDetail = true
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                categoryManager.setupDefaultCategories()
            }
            .alert("Message", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet(categoryManager: categoryManager) { message in
                    alertMessage = message
                    showingAlert = true
                }
                .frame(minWidth: 500, minHeight: 400)
            }
            .sheet(isPresented: $showingCategoryDetail) {
                if let category = selectedCategory {
                    CategoryDetailView(category: category, categoryManager: categoryManager)
                        .frame(minWidth: 700, minHeight: 600)
                }
            }
        }
    }
    
    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            offsets.map { categories[$0] }.forEach { category in
                if category.viewpointCount > 0 {
                    alertMessage = "Cannot delete category '\(category.name ?? "Unknown")' because it contains \(category.viewpointCount) viewpoints."
                    showingAlert = true
                } else {
                    categoryManager.deleteCategory(category)
                }
            }
        }
    }
}

struct CategoryRowView: View {
    let category: CategoryEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Category color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: category.color ?? "#007AFF") ?? .blue)
                    .frame(width: 8, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(category.viewpointCount) viewpoints")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let description = category.categoryDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(category.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let directoryPath = category.directoryPath, !directoryPath.isEmpty {
                        Label("Synced", systemImage: "folder.badge.checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddCategorySheet: View {
    let categoryManager: CategoryManager
    let onComplete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var color = Color.blue
    @State private var directoryPath = ""
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New Category")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Form {
                    Section("Basic Information") {
                        TextField("Category Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Description (optional)", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Text("Color:")
                            Spacer()
                            ColorPicker("Category Color", selection: $color)
                                .labelsHidden()
                        }
                    }
                    
                    Section("Directory Sync") {
                        HStack {
                            Text("Directory Path:")
                            Spacer()
                            if directoryPath.isEmpty {
                                Button("Select Directory") {
                                    showingDirectoryPicker = true
                                }
                                .buttonStyle(.bordered)
                            } else {
                                VStack(alignment: .trailing) {
                                    Text(directoryPath)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    
                                    Button("Change") {
                                        showingDirectoryPicker = true
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        
                        if !directoryPath.isEmpty {
                            Button("Clear Directory") {
                                directoryPath = ""
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        addCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    directoryPath = url.path
                }
            case .failure(let error):
                print("Error selecting directory: \(error)")
            }
        }
    }
    
    private func addCategory() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { return }
        
        // Check if category already exists
        if categoryManager.getCategory(named: trimmedName) != nil {
            onComplete("Category '\(trimmedName)' already exists.")
            dismiss()
            return
        }
        
        let category = categoryManager.createCategory(
            name: trimmedName,
            color: color.toHex(),
            directoryPath: directoryPath.isEmpty ? nil : directoryPath
        )
        
        if !description.isEmpty {
            category.categoryDescription = description
            categoryManager.save()
        }
        
        onComplete("Category '\(trimmedName)' added successfully!")
        dismiss()
    }
}

struct CategoryDetailView: View {
    let category: CategoryEntity
    let categoryManager: CategoryManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isEditing = false
    @State private var editName = ""
    @State private var editDescription = ""
    @State private var editColor = Color.blue
    @State private var editDirectoryPath = ""
    @State private var showingDirectoryPicker = false
    
    private var viewpointManager: ViewpointManager {
        ViewpointManager(viewContext: viewContext)
    }
    
    private var viewpoints: [ViewpointEntity] {
        category.viewpointsArray
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Category Header
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: category.color ?? "#007AFF") ?? .blue)
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name ?? "Unknown")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(category.viewpointCount) viewpoints")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let description = category.categoryDescription, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    }
                    
                    Spacer()
                    
                    Button(isEditing ? "Done" : "Edit") {
                        if isEditing {
                            saveChanges()
                        } else {
                            startEditing()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                if isEditing {
                    editingView
                } else {
                    viewpointsList
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
    
    private var editingView: some View {
        VStack(spacing: 16) {
            TextField("Category Name", text: $editName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Description", text: $editDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Text("Color:")
                Spacer()
                ColorPicker("Category Color", selection: $editColor)
                    .labelsHidden()
            }
            
            HStack {
                Text("Directory:")
                Spacer()
                Button(editDirectoryPath.isEmpty ? "Select" : "Change") {
                    showingDirectoryPicker = true
                }
                .buttonStyle(.bordered)
            }
            
            if !editDirectoryPath.isEmpty {
                HStack {
                    Text(editDirectoryPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Button("Clear") {
                        editDirectoryPath = ""
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    editDirectoryPath = url.path
                }
            case .failure(let error):
                print("Error selecting directory: \(error)")
            }
        }
    }
    
    private var viewpointsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Viewpoints")
                .font(.headline)
            
            if viewpoints.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48, design: .default))
                        .foregroundColor(.secondary)
                    
                    Text("No viewpoints in this category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewpoints, id: \.id) { viewpoint in
                        ViewpointRowView(viewpoint: viewpoint)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func startEditing() {
        editName = category.name ?? ""
        editDescription = category.categoryDescription ?? ""
        editColor = Color(hex: category.color ?? "#007AFF") ?? .blue
        editDirectoryPath = category.directoryPath ?? ""
        isEditing = true
    }
    
    private func saveChanges() {
        categoryManager.updateCategory(
            category,
            name: editName,
            color: editColor.toHex(),
            directoryPath: editDirectoryPath.isEmpty ? nil : editDirectoryPath
        )
        
        category.categoryDescription = editDescription.isEmpty ? nil : editDescription
        categoryManager.save()
        
        isEditing = false
    }
}

#Preview {
    CategoryListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}