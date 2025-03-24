# Big Files Map — Architecture

**Company**: ValiQ Security  
**App Name**: Big Files Map  

## 1. Overview

We use an **MVVM** architecture with additional SwiftData integration. The structure:

- **Model**: File/folder data (`FileNode`), plus SwiftData entities (e.g., `ScanRecord`).
- **View**: SwiftUI views (treemap, sidebar list, metadata panel).
- **ViewModel**: Coordinates scanning logic, data transformation, and user interactions (zoom in/out, delete).

## 2. Components

### 2.1 Models

- **FileNode** (in-memory)
  - `name: String`
  - `path: String`
  - `size: UInt64`
  - `modificationDate: Date?`
  - `isDirectory: Bool`
  - `children: [FileNode]?` (nil or empty if no children)
  
- **Scanner** (class/struct)
  - Enumerates the home directory in a background thread.
  - Constructs the `FileNode` tree with file sizes and metadata.

#### SwiftData Entities

- **ScanRecord** (in SwiftData)
  - `id: UUID` (primary key)
  - `timestamp: Date`
  - `totalHomeDirSize: UInt64`
  - Possibly store partial usage breakdown (e.g., top-level folder sizes).
- **UserPreference** (optional)
  - `lastViewedFolderPath: String?`
  - Additional user settings (theme, color scheme, etc.)

### 2.2 View Models

1. **TreeMapViewModel**  
   - Manages the root `FileNode` for the current treemap display.  
   - Exposes computed properties: total size, sorted children, etc.  
   - Handles zoom in/out transitions by maintaining a stack or reference to parent nodes.

2. **DeletionViewModel**  
   - Handles move-to-trash operations.
   - Updates the `FileNode` tree accordingly, removing or marking deleted items.

3. **DataStoreViewModel** (optional naming)  
   - Interacts with SwiftData to read/write `ScanRecord` or `UserPreference` data.  
   - Saves a new `ScanRecord` after each completed scan.  
   - Loads `lastViewedFolderPath` if needed for “resume” functionality.

### 2.3 Views

1. **MainView**  
   - High-level container holding:
     - **SidebarView** (hierarchy list + metadata panel)
     - **TreemapView** (graphical treemap)
   - Top-level toolbar with “Refresh,” “Back,” and possibly a “Settings” button.

2. **SidebarView**  
   - Displays folders/files in descending size order, with collapsible sub-items.
   - Clicking a folder calls `zoomIn(to:)`.

3. **TreemapView**  
   - A custom SwiftUI view drawing rectangular areas for each child in proportion to file size.
   - Hover highlights and provides metadata on the selected item.
   - Click to zoom in/out.

4. **Metadata Pane**  
   - Shows details when user hovers or selects an item.
   - Includes a “Move to Trash” button for files/folders.

### 2.4 SwiftData Integration

- **ModelContainer**: 
  - Defined in the app’s main entry point (e.g., `@main` struct with a `ModelContainer` in SwiftData).
- **Storing a Scan**:
  - After a full scan, create a `ScanRecord` with the time and total size.
  - Insert it into the `ModelContext` and save (`try context.save()`).
- **Loading Preferences**:
  - On app launch, fetch `UserPreference` entity to see if there is a “lastViewedFolderPath.”
  - If present, the app can automatically “zoom in” to that folder’s node.

## 3. Data Flow

1. **Startup**:
   - SwiftData `ModelContainer` initializes.
   - Load any existing `UserPreference` for last path or user settings.
   - Begin scanning in a background thread.

2. **After Scan Completes**:
   - Construct `FileNode` tree in memory.
   - Create a `ScanRecord`, store top-level summary (optional).
   - Publish new data to `TreeMapViewModel`.

3. **Navigation**:
   - User clicks a folder in the treemap or sidebar → `zoomIn(to:)`.
   - The view model changes the root node, re-renders the treemap.

4. **Deletion**:
   - User clicks “Move to Trash” → `DeletionViewModel` calls `NSWorkspace.shared.recycle([URL])`.
   - The corresponding node is removed from memory.
   - UI updates to reflect new usage.

5. **Refresh**:
   - Clears the in-memory tree (or sets aside).
   - Re-scans from the home directory.
   - Optionally records another `ScanRecord`.

## 4. Security & Sandboxing

- Sandboxed environment with read permissions for the home directory.
- File deletions use the system Trash.
- SwiftData usage is fully contained within the app’s sandbox container.

## 5. Summary

This architecture combines:
- In-memory scanning (fast, ephemeral),
- SwiftData for saving minimal records (scan history, preferences),
- A SwiftUI-based UI for the treemap, lists, and metadata display.

The final result is a responsive disk usage analyzer with optional persistent data for convenience and short histories.