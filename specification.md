# Big Files Map — Specification

**Company**: ValiQ Security  
**App Name**: Big Files Map  

## 1. Overview

Big Files Map (BFM) is a macOS application (built with Swift, SwiftUI, and SwiftData) that provides a treemap visualization of disk usage within the **user’s home directory** (e.g., `/Users/username`). It highlights which folders and files consume the most space, allowing users to easily identify and remove large, unnecessary files.

## 2. Primary Goal

- **Goal**: Help users clean up their disk space by providing a clear, high-level visualization of file and folder sizes within their home directory.  
- **Core Feature**: A fully interactive treemap that supports zooming into subfolders, showing metadata, and allowing file deletion directly from the UI.  
- **Secondary Goal (SwiftData)**: Persist limited data (e.g. user preferences or last-scan summaries) for convenience across app launches.

## 3. Requirements

1. **Platform**: macOS, distributed via Mac App Store (Sandboxed).
2. **Language & Frameworks**: 
   - Swift 5+
   - SwiftUI for the UI
   - **SwiftData** for persistence
3. **Permissions**:  
   - Sandboxed with “User Selected File” or “Home Directory” read access.  
   - Minimal user permission prompts (if needed) for Documents, etc.
4. **Scanning**:
   - Targets the **home directory** by default.
   - **No incremental scanning**; results are displayed after the full scan completes.
   - **Background scanning**: The scanner runs off the main thread to keep the UI responsive.
   - **Relative threshold** for file/folder display: extremely small files may be combined or labeled as “Other.”
5. **Treemap Visualization**:
   - Main window with:
     - **Left Panel**: A hierarchical list of folders/files (sorted by size).
     - **Right Panel**: A treemap of the same data.
   - Hovering highlights a file/folder and shows metadata.  
   - Clicking on a folder zooms in (makes that folder the new root).
6. **Interaction & Features**:
   - Hover highlights
   - Zoom in/out to navigate folder structure
   - Delete files/folders (moves them to Trash)
   - **Sidebar Metadata**: show size, path, last modified date
7. **SwiftData Persistence**:
   - Optionally store a **ScanRecord** containing:
     - Timestamp of scan
     - Total size of the home directory
     - Possibly top-level usage breakdown
   - Store minimal user preferences (e.g., UI settings, color scheme, or last viewed folder).
8. **Caching & Refresh**:
   - Cache the scan results **in memory** during the current session.
   - **Refresh** button to re-scan if the user modifies files externally.

## 4. Out of Scope / Future Enhancements

- **Pro Mode**: Scanning other directories, network drives, external disks.
- **Export**: No CSV/PDF or full export of the treemap data.
- **Pie Chart**: Treemap only.

## 5. Constraints

- Must remain responsive, even for large user home directories.
- Sandbox-friendly: all scanning and trashing must comply with macOS sandbox entitlements.
- SwiftData usage should be minimal so as not to overly complicate the scanning logic.

## 6. Testing & Validation

- Test with home directories of varying sizes and complexities.
- Verify deletion logic (items go to Trash).
- Validate that reported sizes match standard disk usage tools.
- Confirm that SwiftData properly stores & retrieves minimal user preferences or scan summaries.