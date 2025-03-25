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
    
    private let fileManager = FileManager.default
    
    func selectAndScanDirectory() async throws -> FileNode {
        // Get directory URL on the main thread
        let url = try await selectDirectory()
        // Now scan the directory
        return try await Task.detached { [url] in
            try await self.scanDirectory(at: url)
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
    
    // Move scanning to a non-actor-isolated context
    nonisolated
    func scanDirectory(at url: URL) async throws -> FileNode {
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
            
            for childURL in contents {
                do {
                    let childNode = try await scanDirectory(at: childURL)
                    children.append(childNode)
                    totalSize += childNode.size
                } catch {
                    print("Skipping \(childURL): \(error.localizedDescription)")
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