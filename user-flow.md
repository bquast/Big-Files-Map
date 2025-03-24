# Big Files Map — User Flow

**Company**: ValiQ Security  
**App Name**: Big Files Map  

## 1. Launching the App

1. The user opens Big Files Map from the Dock or Applications folder.
2. On first launch, macOS may prompt for permission to access the user’s home directory (sandbox read access).
3. The app loads any stored SwiftData preferences (e.g. lastViewedFolderPath, UI settings).

## 2. Initial State (Scanning)

- Main window:
  - **Sidebar**: Shows a spinner or "Scanning..." message.
  - **Treemap**: Blank or placeholder with a loading indicator.
- **Refresh** button is disabled until the scan finishes.

## 3. Displaying Results

1. After the full scan completes:
   - The **Sidebar** lists top-level folders of the home directory in descending size order.
   - The **Treemap** displays subdivided rectangles for each top-level folder.
   - A new `ScanRecord` is saved to SwiftData, logging the timestamp and total size.
2. If a **lastViewedFolderPath** was stored, the app may auto-navigate to that folder’s node.

## 4. Hover & Highlight

- Moving the mouse over a rectangle:
  - Highlight that rectangle (lighter fill, border, etc.).
  - **Metadata Pane** shows:
    - Name
    - Full path
    - Size
    - Last modified date
  - If the item is a folder, the user can see an approximate subfolder size breakdown in the treemap (depending on zoom level).

## 5. Navigation (Zoom In / Zoom Out)

### 5.1 Zoom In
- **Click** on a folder rectangle or a folder entry in the sidebar.
- The selected folder becomes the **new root**.
- The sidebar refreshes to show that folder’s children in descending size.
- The treemap updates, making the selected folder’s contents 100% of the space.

### 5.2 Zoom Out
- **Click** the “Back” or “Up One Level” button in the toolbar.
- The previous folder becomes the active root.

### 5.3 Storing & Using Last-Viewed Folder
- When a user navigates to a folder, the app might update a SwiftData `UserPreference` with `lastViewedFolderPath`.
- On the next launch, the app automatically zooms in to that folder after scanning completes (optional).

## 6. Deleting Items

1. Hover/select an item (file or folder).
2. The **Metadata Pane** shows a “Move to Trash” button (disabled for the root).
3. Clicking “Move to Trash” calls the system trash API.
4. The item is removed from the in-memory data structure; sizes update in the treemap and sidebar.
5. If the user wants to confirm or see system-level trash states, they can open Finder’s Trash.

## 7. Refresh

- **Refresh** button in the toolbar:
  - Triggers a new full scan.
  - Replaces the entire data model with fresh results.
  - Optionally records a new `ScanRecord` (timestamp, total size, etc.).

## 8. End of Session

- When the user quits:
  - SwiftData saves any updated `UserPreference` (like `lastViewedFolderPath`).
  - On next launch, a fresh scan occurs, and the app can recall the last view if desired.

## 9. Edge Cases

- **Permission Denied**: If the user doesn’t grant home folder access, the treemap remains empty or partially complete. Display a clear message.
- **Large Folders**: The app remains responsive because scanning is off the main thread.
- **Tiny Files**: Appear as very small rectangles or grouped as “Other.”

## 10. Summary

The user flow provides a straightforward experience:
- Launch → Scan → Treemap & Sidebar → Hover to see metadata → Click to zoom → Delete as needed → Optional Refresh → Quit.
- Light SwiftData usage remembers the user’s last location and logs minimal historical scan info.