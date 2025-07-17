# WriteHub Architecture Design

## Technology Stack
- **Platform**: macOS native application
- **UI Framework**: SwiftUI
- **Database**: Core Data (SQLite backend)
- **Language**: Swift 5.9+
- **Minimum OS**: macOS 12.0+

## Core Components

### 1. Data Layer
- **ViewpointEntity**: Core Data entity for storing viewpoints
- **CategoryEntity**: Core Data entity for categories
- **DailyStatsEntity**: Core Data entity for daily statistics

### 2. Business Logic
- **ViewpointManager**: CRUD operations for viewpoints
- **CategoryManager**: Category management
- **StatisticsManager**: Daily/weekly/monthly statistics
- **FileSystemManager**: Export/import to directories

### 3. UI Components
- **MainView**: Tab-based main interface
- **ViewpointInputView**: Text input for new viewpoints
- **ContributionGraphView**: GitHub-style contribution graph
- **CategoryListView**: Category management interface
- **StatisticsView**: Analytics and insights

### 4. Features
- Daily viewpoint tracking
- Category-based organization
- GitHub-style contribution visualization
- File system integration (export to directories)
- Statistics and analytics
- Search and filtering

## File Structure
```
WriteHub/
├── WriteHub.xcodeproj
├── WriteHub/
│   ├── WriteHubApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── ViewpointEntity.swift
│   │   ├── CategoryEntity.swift
│   │   └── DailyStatsEntity.swift
│   ├── Views/
│   │   ├── ViewpointInputView.swift
│   │   ├── ContributionGraphView.swift
│   │   ├── CategoryListView.swift
│   │   └── StatisticsView.swift
│   ├── Managers/
│   │   ├── ViewpointManager.swift
│   │   ├── CategoryManager.swift
│   │   ├── StatisticsManager.swift
│   │   └── FileSystemManager.swift
│   ├── Utils/
│   │   └── Extensions.swift
│   └── Resources/
│       └── WriteHub.xcdatamodeld
```