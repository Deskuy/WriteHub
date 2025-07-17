import SwiftUI

struct ViewpointDetailView: View {
    let viewpoint: ViewpointEntity
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isEditing = false
    @State private var editContent = ""
    @State private var editCategory = ""
    @State private var showingDeleteConfirmation = false
    
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
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewpoint.category ?? "Uncategorized")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text(viewpoint.createdAt?.formatted(date: .complete, time: .shortened) ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                
                // Content
                if isEditing {
                    editingView
                } else {
                    readOnlyView
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .alert("Delete Viewpoint", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteViewpoint()
                }
            } message: {
                Text("Are you sure you want to delete this viewpoint? This action cannot be undone.")
            }
        }
    }
    
    private var readOnlyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content")
                .font(.headline)
            
            ScrollView {
                Text(viewpoint.content ?? "")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
            }
        }
    }
    
    private var editingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                
                Picker("Category", selection: $editCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Content Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.headline)
                
                TextEditor(text: $editContent)
                    .font(.body)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 1)
                    )
                    .frame(minHeight: 200)
            }
        }
    }
    
    private func startEditing() {
        editContent = viewpoint.content ?? ""
        editCategory = viewpoint.category ?? "General"
        isEditing = true
    }
    
    private func saveChanges() {
        let trimmedContent = editContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else {
            isEditing = false
            return
        }
        
        viewpointManager.updateViewpoint(viewpoint, content: trimmedContent, category: editCategory)
        isEditing = false
    }
    
    private func deleteViewpoint() {
        viewpointManager.deleteViewpoint(viewpoint)
        dismiss()
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            ViewpointInputView()
                .tabItem {
                    Label("New Viewpoint", systemImage: "plus.circle")
                }
                .tag(1)
            
            ContributionGraphView()
                .tabItem {
                    Label("Contribution", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            CategoryListView()
                .tabItem {
                    Label("Categories", systemImage: "folder")
                }
                .tag(3)
            
            StatisticsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.pie")
                }
                .tag(4)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ViewpointEntity.createdAt, ascending: false)],
        animation: .default)
    private var viewpoints: FetchedResults<ViewpointEntity>
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("WriteHub")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                HStack {
                    StatsCard(title: "Total Viewpoints", value: "\(viewpoints.count)", icon: "doc.text.fill", color: .blue)
                    StatsCard(title: "This Month", value: "\(viewpointsThisMonth)", icon: "calendar", color: .green)
                    StatsCard(title: "This Week", value: "\(viewpointsThisWeek)", icon: "calendar.circle", color: .orange)
                }
                
                Text("Recent Viewpoints")
                    .font(.headline)
                    .padding(.top)
                
                List {
                    ForEach(Array(viewpoints.prefix(10)), id: \.self) { viewpoint in
                        ViewpointRowView(viewpoint: viewpoint)
                    }
                }
                .listStyle(PlainListStyle())
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var viewpointsThisMonth: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return viewpoints.filter { $0.createdAt ?? Date() >= startOfMonth }.count
    }
    
    private var viewpointsThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return viewpoints.filter { $0.createdAt ?? Date() >= startOfWeek }.count
    }
}


struct ViewpointRowView: View {
    let viewpoint: ViewpointEntity
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewpoint.content ?? "")
                    .lineLimit(3)
                    .font(.body)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(viewpoint.category ?? "Uncategorized")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(viewpoint.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            ViewpointDetailView(viewpoint: viewpoint)
                .frame(minWidth: 600, minHeight: 500)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}