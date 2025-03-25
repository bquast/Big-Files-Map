import Foundation
import AppKit

@MainActor // Add this to ensure UI operations happen on main thread
class FileScanner {
    enum ScannerError: Error, LocalizedError {
        case accessDenied
        case scanningFailed(String)
        case noDirectorySelected
        
        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Access denied. Please check permissions."
            case .scanningFailed(let message):
                return "Failed to scan: \(message)"
            case .noDirectorySelected:
                return "No directory selected"
            }
        }
    }
    
    func selectAndScanDirectory() async throws -> FileNode {
        let url = try await selectDirectory()
        // Create a new scanner task with its own FileManager instance
        return try await Task.detached {
            try await Self.scanDirectory(at: url)
        }.value
    }
    
    // New method to handle directory selection
    @MainActor
    private func selectDirectory() async throws -> URL {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to analyze"
        panel.prompt = "Analyze"
        
        let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
        
        guard response == .OK, let url = panel.url else {
            throw ScannerError.noDirectorySelected
        }
        
        return url
    }
    
    // Make this a static method so it doesn't need access to instance properties
    static nonisolated
    func scanDirectory(at url: URL) async throws -> FileNode {
        // Create a new FileManager instance for this task
        let fileManager = FileManager()
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw ScannerError.accessDenied
        }
        
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let modDate = attributes[.modificationDate] as? Date
        
        if !isDirectory.boolValue {
            // This is a file
            let size = attributes[.size] as? UInt64 ?? 0
            return FileNode(
                name: url.lastPathComponent,
                path: url,
                size: size,
                modificationDate: modDate,
                isDirectory: false,
                children: nil
            )
        }
        
        // This is a directory, scan its contents
        var children: [FileNode] = []
        var totalSize: UInt64 = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            // Use TaskGroup for concurrent directory scanning
            try await withThrowingTaskGroup(of: FileNode.self) { group in
                for childURL in contents {
                    group.addTask {
                        try await Self.scanDirectory(at: childURL)
                    }
                }
                
                // Collect results
                for try await childNode in group {
                    children.append(childNode)
                    totalSize += childNode.size
                }
            }
            
            children.sort { $0.size > $1.size }
            
        } catch {
            throw ScannerError.scanningFailed("Failed to scan \(url.path): \(error.localizedDescription)")
        }
        
        return FileNode(
            name: url.lastPathComponent,
            path: url,
            size: totalSize,
            modificationDate: modDate,
            isDirectory: true,
            children: children
        )
    }
} 