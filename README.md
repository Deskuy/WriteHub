# WriteHub

A native macOS application for tracking daily viewpoint output with GitHub-style contribution visualization.

## Features

- **Daily Viewpoint Tracking**: Record your thoughts and observations with timestamp and word count
- **Category Management**: Organize viewpoints into customizable categories with color coding
- **GitHub-style Contribution Graph**: Visual representation of your writing activity over time
- **File System Integration**: Export viewpoints to organized directories by category
- **Statistics & Analytics**: Comprehensive statistics including streaks, word counts, and category distribution
- **Data Export/Import**: Backup and restore functionality with JSON format

## Requirements

- macOS 12.0 or later
- Xcode 15.0 or later (for building from source)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/writehub.git
   cd writehub
   ```

2. Open `WriteHub.xcodeproj` in Xcode

3. Build and run the application

## Usage

### Creating Viewpoints

1. Click on the "New Viewpoint" tab
2. Select a category from the dropdown (or create a new one)
3. Type your viewpoint in the text area
4. Click "Save Viewpoint"

### Managing Categories

1. Go to the "Categories" tab
2. Click the "+" button to add a new category
3. Customize category name, color, and optional directory path
4. Edit or delete existing categories as needed

### Viewing Statistics

1. Navigate to the "Statistics" tab to see:
   - Total viewpoints, words, and characters
   - Writing streaks (current and longest)
   - Category distribution
   - Time-based analysis

### Contribution Graph

1. Visit the "Contribution" tab to see:
   - GitHub-style yearly contribution graph
   - Click on any day to see detailed statistics
   - Navigate between years using arrow buttons

### File System Integration

WriteHub automatically exports viewpoints to your Documents folder:
- Base directory: `~/Documents/WriteHub_Export/`
- Organized by category in subdirectories
- Plain text files with metadata headers

## Architecture

The application follows a clean architecture pattern:

- **Models**: Core Data entities for viewpoints, categories, and statistics
- **Views**: SwiftUI views for the user interface
- **Managers**: Business logic for data operations
- **Utils**: Extensions and utility functions

## Data Storage

- **Core Data**: Local SQLite database for persistent storage
- **File System**: Optional export to text files in organized directories
- **JSON Backup**: Full backup/restore functionality

## Development

### Project Structure

```
WriteHub/
├── WriteHub/
│   ├── WriteHubApp.swift          # Main app entry point
│   ├── ContentView.swift          # Main tab view
│   ├── Models/                    # Core Data models
│   ├── Views/                     # SwiftUI views
│   ├── Managers/                  # Business logic
│   ├── Utils/                     # Extensions and utilities
│   └── Resources/                 # Assets and Core Data model
```

### Building

1. Open `WriteHub.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run (⌘R)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

If you encounter any issues or have suggestions, please open an issue on GitHub.