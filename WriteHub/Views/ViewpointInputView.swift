import SwiftUI

struct ViewpointInputView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var content = ""
    @State private var selectedCategory = "General"
    @State private var showingCategorySheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var wordCount = 0
    @State private var characterCount = 0
    
    @FocusState private var isTextFieldFocused: Bool
    
    private var viewpointManager: ViewpointManager {
        ViewpointManager(viewContext: viewContext)
    }
    
    private var categoryManager: CategoryManager {
        CategoryManager(viewContext: viewContext)
    }
    
    private var categories: [String] {
        categoryManager.getCategoryNames()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("New Viewpoint")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Category Selection
                HStack {
                    Text("Category:")
                        .font(.headline)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Button(action: {
                        showingCategorySheet = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                
                // Text Input Area
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Content:")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(wordCount) words, \(characterCount) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: $content)
                        .font(.system(size: 14, design: .monospaced))
                        .padding(8)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separatorColor), lineWidth: 1)
                        )
                        .focused($isTextFieldFocused)
                        .onChange(of: content) { newValue in
                            updateWordCount()
                        }
                    
                    if content.isEmpty {
                        Text("Write your viewpoint here...")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14, design: .monospaced))
                            .padding(.leading, 12)
                            .padding(.top, -280)
                            .allowsHitTesting(false)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Clear") {
                        content = ""
                        updateWordCount()
                    }
                    .buttonStyle(.bordered)
                    .disabled(content.isEmpty)
                    
                    Spacer()
                    
                    Button("Save Viewpoint") {
                        saveViewpoint()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                setupDefaultCategories()
                isTextFieldFocused = true
            }
            .alert("Message", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingCategorySheet) {
                CategoryManagementSheet(
                    selectedCategory: $selectedCategory,
                    categoryManager: categoryManager
                )
                .frame(minWidth: 500, minHeight: 400)
            }
        }
    }
    
    private func updateWordCount() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        wordCount = trimmedContent.isEmpty ? 0 : trimmedContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        characterCount = content.count
    }
    
    private func saveViewpoint() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else {
            alertMessage = "Please enter some content for your viewpoint."
            showingAlert = true
            return
        }
        
        let viewpoint = viewpointManager.createViewpoint(
            content: trimmedContent,
            category: selectedCategory
        )
        
        // Export to file system
        let fileManager = FileSystemManager(viewContext: viewContext)
        do {
            let _ = try fileManager.exportViewpoint(viewpoint)
        } catch {
            print("Error exporting viewpoint: \(error)")
        }
        
        // Clear form
        content = ""
        updateWordCount()
        
        alertMessage = "Viewpoint saved successfully!"
        showingAlert = true
        
        // Refocus text field
        isTextFieldFocused = true
    }
    
    private func setupDefaultCategories() {
        categoryManager.setupDefaultCategories()
    }
}

struct CategoryManagementSheet: View {
    @Binding var selectedCategory: String
    let categoryManager: CategoryManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var newCategoryName = ""
    @State private var newCategoryColor = "#007AFF"
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var categories: [CategoryEntity] {
        categoryManager.getCategories()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Manage Categories")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Add New Category Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add New Category")
                        .font(.headline)
                    
                    HStack {
                        TextField("Category name", text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        ColorPicker("Color", selection: Binding(
                            get: { Color(hex: newCategoryColor) ?? .blue },
                            set: { newCategoryColor = $0.toHex() }
                        ))
                        .labelsHidden()
                        .frame(width: 40, height: 30)
                        
                        Button("Add") {
                            addCategory()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                // Existing Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Existing Categories")
                        .font(.headline)
                    
                    List {
                        ForEach(categories, id: \.id) { category in
                            HStack {
                                Circle()
                                    .fill(Color(hex: category.color ?? "#007AFF") ?? .blue)
                                    .frame(width: 16, height: 16)
                                
                                Text(category.name ?? "Unknown")
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("\(category.viewpointCount) viewpoints")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Message", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { return }
        
        // Check if category already exists
        if categoryManager.getCategory(named: trimmedName) != nil {
            alertMessage = "Category '\(trimmedName)' already exists."
            showingAlert = true
            return
        }
        
        let _ = categoryManager.createCategory(name: trimmedName, color: newCategoryColor)
        selectedCategory = trimmedName
        
        newCategoryName = ""
        newCategoryColor = "#007AFF"
        
        alertMessage = "Category '\(trimmedName)' added successfully!"
        showingAlert = true
    }
}


#Preview {
    ViewpointInputView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}